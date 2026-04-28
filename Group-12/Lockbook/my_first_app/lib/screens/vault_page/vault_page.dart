import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../main.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<Map<String, dynamic>> vault = [];
  List<Map<String, dynamic>> filteredVault = [];

  final sourceController = TextEditingController();
  final linkController = TextEditingController();
  final userController = TextEditingController();
  final passController = TextEditingController();
  final searchController = TextEditingController();

  bool allowAccess = false;
  bool isSaving = false;
  bool hasShownPopup = false;
  bool hasTriggeredByTouch = false;

  final List<Color> cardColors = [
    const Color(0xffE3F2FD),
    const Color(0xffE8F5E9),
    const Color(0xffFFF3E0),
    const Color(0xffF3E5F5),
    const Color(0xffE0F7FA),
  ];

  @override
  void initState() {
    super.initState();
    loadVault();
  }

  Future<void> loadVault() async {
    hasShownPopup = false;
    hasTriggeredByTouch = false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vault')
        .get();

    vault = snapshot.docs.map((doc) {
      return {
        ...doc.data(),
        "docId": doc.id,
      };
    }).toList();

    filteredVault = List.from(vault);

    if (mounted) {
      setState(() {});
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        checkForOldPasswords();
      }
    });
  }

  void searchVault(String query) {
    if (query.isEmpty) {
      filteredVault = List.from(vault);
    } else {
      filteredVault = vault.where((item) {
        return item["source"].toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  Future<void> openLink(String url) async {
    if (url.isEmpty) return;

    final Uri uri = Uri.parse(url.startsWith("http") ? url : "https://$url");

    await launchUrl(uri);
  }

  String getFavicon(String link) {
    if (link.isEmpty) return "";

    Uri uri = Uri.parse(
      link.startsWith("http") ? link : "https://$link",
    );

    return "https://www.google.com/s2/favicons?sz=64&domain=${uri.host}";
  }

  String formatDate(String time) {
    DateTime t = DateTime.parse(time);

    const months = [
      "",
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];

    return "${t.day.toString().padLeft(2, '0')} ${months[t.month]} ${t.year}";
  }

  String timeAgo(String time) {
    DateTime t = DateTime.parse(time);
    Duration diff = DateTime.now().difference(t);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} min ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} hrs ago";
    } else {
      return "${diff.inDays} days ago";
    }
  }

  bool isPasswordOld(String time) {
    DateTime t = DateTime.parse(time);
    Duration diff = DateTime.now().difference(t);
    return diff.inDays >= 30;
  }

  void openOldPasswordForUpdate() {
    for (int i = 0; i < filteredVault.length; i++) {
      if (isPasswordOld(filteredVault[i]["updated"])) {
        editPassword(i);
        return;
      }
    }

    for (int i = 0; i < vault.length; i++) {
      if (isPasswordOld(vault[i]["updated"])) {
        final oldDocId = vault[i]["docId"];
        final indexInFiltered =
            filteredVault.indexWhere((item) => item["docId"] == oldDocId);

        if (indexInFiltered != -1) {
          editPassword(indexInFiltered);
        }
        return;
      }
    }
  }

  Future<void> addPassword() async {
    if (isSaving) return;

    if (sourceController.text.trim().isEmpty ||
        passController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      final source = sourceController.text.trim();
      final link = linkController.text.trim();
      final username = userController.text.trim();
      final pass = passController.text.trim();

      final vaultRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('vault');

      final existing = await vaultRef
          .where("source", isEqualTo: source)
          .where("username", isEqualTo: username)
          .get();

      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update({
          "source": source,
          "link": link,
          "username": username,
          "pass": pass,
          "visible": false,
          "access": allowAccess,
          "updated": DateTime.now().toIso8601String(),
        });

        hasShownPopup = false;
        hasTriggeredByTouch = false;
        await loadVault();

        sourceController.clear();
        linkController.clear();
        userController.clear();
        passController.clear();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Existing entry updated successfully")),
          );
        }
      } else {
        final newData = {
          "source": source,
          "link": link,
          "username": username,
          "pass": pass,
          "visible": false,
          "access": allowAccess,
          "created": DateTime.now().toIso8601String(),
          "updated": DateTime.now().toIso8601String(),
        };

        await vaultRef.add(newData);

        hasShownPopup = false;
        hasTriggeredByTouch = false;
        await loadVault();

        sourceController.clear();
        linkController.clear();
        userController.clear();
        passController.clear();

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Saved successfully")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void editPassword(int index) {
    sourceController.text = filteredVault[index]["source"];
    linkController.text = filteredVault[index]["link"];
    userController.text = filteredVault[index]["username"];
    passController.text = filteredVault[index]["pass"];
    allowAccess = filteredVault[index]["access"];

    showDialog(
      context: context,
      builder: (context) {
        bool showPass = false;
        bool autoFill = allowAccess;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Secure Source ✏️"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: sourceController,
                      decoration: const InputDecoration(
                        labelText: "Source Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        labelText: "Website Link",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passController,
                      obscureText: !showPass,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPass
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              showPass = !showPass;
                            });
                          },
                        ),
                      ),
                    ),
                    SwitchListTile(
                      value: autoFill,
                      onChanged: (v) {
                        setState(() {
                          autoFill = v;
                        });
                      },
                      title: const Text("Enable AutoFill"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) return;

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('vault')
                        .doc(filteredVault[index]["docId"])
                        .update({
                      "source": sourceController.text.trim(),
                      "link": linkController.text.trim(),
                      "username": userController.text.trim(),
                      "pass": passController.text.trim(),
                      "access": autoFill,
                      "updated": DateTime.now().toIso8601String(),
                    });

                    hasShownPopup = false;
                    hasTriggeredByTouch = false;
                    await loadVault();

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Password updated successfully"),
                        ),
                      );
                    }
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> deletePassword(int i) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vault')
        .doc(filteredVault[i]["docId"])
        .delete();

    hasShownPopup = false;
    hasTriggeredByTouch = false;
    await loadVault();
  }

  void showPasswordReminderPopup() {
    if (!mounted) return;
    if (hasShownPopup) return;

    hasShownPopup = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Password Update Reminder"),
        content: const Text(
          "If your saved password has changed recently, please update it in LockBook for secure and seamless access.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              searchController.clear();
              filteredVault = List.from(vault);
              setState(() {});
              Future.delayed(const Duration(milliseconds: 200), () {
                if (!mounted) return;
                openOldPasswordForUpdate();
              });
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }

  void checkForOldPasswords() {
  if (hasShownPopup) return;

  for (var item in vault) {
    if (isPasswordOld(item["updated"])) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || hasShownPopup) return;

        try {
          await showPasswordReminderNotification();
        } catch (e) {
          debugPrint("Notification error: $e");
        }

        if (!mounted || hasShownPopup) return;
        showPasswordReminderPopup();
      });
      break;
    }
  }
}

 Future<void> triggerPopupOnInteraction() async {
  if (hasTriggeredByTouch) return;
  if (hasShownPopup) return;

  final hasOld = vault.any((item) => isPasswordOld(item["updated"]));
  if (!hasOld) return;

  hasTriggeredByTouch = true;

  try {
    await showPasswordReminderNotification();
  } catch (e) {
    debugPrint("Notification error: $e");
  }

  if (!mounted || hasShownPopup) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted || hasShownPopup) return;
    showPasswordReminderPopup();
  });
}

  Future<void> showPasswordReminderNotification() async {
  try {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'password_reminder_channel_v2',
      'Password Reminder',
      description: 'Reminds users to update old passwords',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'password_reminder_channel_v2',
      'Password Reminder',
      channelDescription: 'Reminds users to update old passwords',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      999,
      'LockBook Reminder',
      'If your saved password has changed recently, please update it in LockBook for secure and seamless access.',
      notificationDetails,
    );
  } catch (e) {
    debugPrint("Notification failed: $e");
  }
}

  void copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  Widget vaultCard(int i) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    var item = filteredVault[i];

    return Card(
      color: isDark
          ? const Color(0xFF1E1E1E)
          : cardColors[i % cardColors.length],
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.network(
                  getFavicon(item["link"]),
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    radius: 15,
                    child: Text(
                      item["source"][0].toUpperCase(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item["source"],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text("Username : ${item["username"]}")),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => copyText(item["username"]),
                )
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item["visible"]
                        ? "Password : ${item["pass"]}"
                        : "Password : ********",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => copyText(item["pass"]),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text("Created : ${formatDate(item["created"])}"),
            Text("Updated : ${formatDate(item["updated"])}"),
            Text(
              "Time : ${timeAgo(item["updated"])}",
              style: TextStyle(
                color: isPasswordOld(item["updated"]) ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 4),
            if (isPasswordOld(item["updated"]))
              const Text(
                "⚠ Password update recommended",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    item["visible"]
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      item["visible"] = !item["visible"];
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => editPassword(i),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => openLink(item["link"] ?? ""),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deletePassword(i),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Vault 🔐"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showDialogBox,
        child: const Icon(Icons.add),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          triggerPopupOnInteraction();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            triggerPopupOnInteraction();
            return false;
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: searchController,
                  onChanged: searchVault,
                  decoration: const InputDecoration(
                    hintText: "Search vault...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: filteredVault.isEmpty
                    ? const Center(child: Text("No Secure Data"))
                    : ListView.builder(
                        itemCount: filteredVault.length,
                        itemBuilder: (context, i) {
                          return vaultCard(i);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showDialogBox() {
    showDialog(
      context: context,
      builder: (context) {
        bool showPass = false;
        bool autoFill = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Secure Source 🔐"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: sourceController,
                      decoration: const InputDecoration(
                        labelText: "Source Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: linkController,
                      decoration: const InputDecoration(
                        labelText: "Website Link",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: userController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passController,
                      obscureText: !showPass,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showPass
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              showPass = !showPass;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: autoFill,
                      onChanged: (v) {
                        setState(() {
                          autoFill = v;
                        });
                      },
                      title: const Text("Enable AutoFill"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          allowAccess = autoFill;
                          await addPassword();
                        },
                  child: Text(isSaving ? "Saving..." : "Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}