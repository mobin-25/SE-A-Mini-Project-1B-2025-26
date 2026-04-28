import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:reusex/screens/home/phone_buy_button/phone_buy_button.dart';
import 'package:reusex/screens/recycle/recycle_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String userName = "User";
  bool isUserLoading = true;
  String selectedCategory = "All";

  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  Future<void> _getUserName() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        setState(() {
          userName = "User";
          isUserLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          userName = (data?["name"] ?? "User").toString();
          isUserLoading = false;
        });
      } else {
        setState(() {
          userName = "User";
          isUserLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = "User";
        isUserLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserName();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _buildCategoryImage(String imagePath) {
    if (imagePath.trim().isNotEmpty && imagePath.startsWith("http")) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.category,
            color: Colors.green,
            size: 34,
          );
        },
      );
    }

    return const Icon(
      Icons.category,
      color: Colors.green,
      size: 34,
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.trim().isNotEmpty && imageUrl.startsWith("http")) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        width: 110,
        height: 110,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported,
            color: Colors.grey,
            size: 50,
          );
        },
      );
    }

    return const Icon(
      Icons.image,
      color: Colors.grey,
      size: 50,
    );
  }

  double _parsePrice(dynamic rawPrice) {
    if (rawPrice == null) return 0.0;
    if (rawPrice is num) return rawPrice.toDouble();

    String cleanedPrice = rawPrice.toString().trim();
    cleanedPrice = cleanedPrice
        .replaceAll("₹", "")
        .replaceAll("Rs.", "")
        .replaceAll("RS.", "")
        .replaceAll("Rs", "")
        .replaceAll("rs.", "")
        .replaceAll("rs", "")
        .replaceAll(",", "")
        .trim();

    return double.tryParse(cleanedPrice) ?? 0.0;
  }

  String _formatIndianPrice(double price) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return "₹${formatter.format(price)}";
  }

  List<Map<String, dynamic>> _filterProducts(
      List<Map<String, dynamic>> products,
      ) {
    List<Map<String, dynamic>> filtered = products;

    if (selectedCategory != "All") {
      filtered = filtered
          .where((item) => item["category"] == selectedCategory)
          .toList();
    }

    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return filtered;
    }

    final queryWords =
    query.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

    int getScore(Map<String, dynamic> product) {
      final title = (product["title"] ?? "").toString().toLowerCase();
      final category = (product["category"] ?? "").toString().toLowerCase();
      final description =
      (product["description"] ?? "").toString().toLowerCase();
      final grade = (product["gradeLevel"] ?? "").toString().toLowerCase();

      int score = 0;

      if (title == query) score += 100;
      if (title.startsWith(query)) score += 80;
      if (title.contains(query)) score += 60;
      if (category.contains(query)) score += 40;
      if (description.contains(query)) score += 30;
      if (grade.contains(query)) score += 10;

      for (final word in queryWords) {
        if (title.contains(word)) score += 20;
        if (category.contains(word)) score += 10;
        if (description.contains(word)) score += 8;
      }

      return score;
    }

    final scoredProducts = filtered.map((product) {
      return {
        ...product,
        "_searchScore": getScore(product),
      };
    }).where((product) {
      return (product["_searchScore"] as int) > 0;
    }).toList();

    scoredProducts.sort((a, b) {
      final scoreCompare =
      (b["_searchScore"] as int).compareTo(a["_searchScore"] as int);
      if (scoreCompare != 0) return scoreCompare;

      final titleA = (a["title"] ?? "").toString().toLowerCase();
      final titleB = (b["title"] ?? "").toString().toLowerCase();
      return titleA.compareTo(titleB);
    });

    return scoredProducts;
  }

  void _openProductDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneBuyButton(
          productName: (product["title"] ?? "").toString(),
          productImage: (product["imageUrl"] ?? "").toString(),
          description:
          (product["description"]?.toString().trim().isNotEmpty == true)
              ? product["description"].toString()
              : "No description available",
          price: (product["priceRaw"] as num?)?.toDouble() ?? 0.0,
          oldPrice: null,
          gradeLevel:
          (product["gradeLevel"]?.toString().trim().isNotEmpty == true)
              ? product["gradeLevel"].toString()
              : "A",
          inspectionHistory:
          (product["inspectionHistory"]?.toString().trim().isNotEmpty ==
              true)
              ? product["inspectionHistory"].toString()
              : "This product has been inspected and is in good working condition.",
          category: (product["category"] ?? "General").toString(),
        ),
      ),
    );
  }

  void _clearSearch() {
    searchController.clear();
    setState(() {
      searchQuery = "";
    });
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return GestureDetector(
      onTap: () => _openProductDetails(product),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF2E7D32),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: Center(
                child: _buildProductImage(
                  (product["imageUrl"] ?? "").toString(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Title
            SizedBox(
              height: 36,
              child: Text(
                (product["title"] ?? "").toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Price
            Text(
              (product["price"] ?? "").toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 2),
            // Category
            Text(
              (product["category"] ?? "").toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            // Grade
            Text(
              (product["gradeLevel"]?.toString().isNotEmpty == true)
                  ? "Grade: ${product["gradeLevel"]}"
                  : "Grade: -",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            // Buy Now button — always at bottom, inside border
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _openProductDetails(product),
                child: const Text(
                  "Buy Now",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveProductGrid(
      List<Map<String, dynamic>> filteredProducts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card dimensions based on actual screen width
        const crossAxisCount = 2;
        const horizontalPadding = 24.0; // 12 left + 12 right
        const spacing = 12.0;

        final cardWidth = (constraints.maxWidth - horizontalPadding - spacing) /
            crossAxisCount;

        // Fixed content heights:
        // image(flex, ~120) + title(36) + price(18) + category(15) + grade(15)
        // + button(38) + paddings(12+12+6+4+2+2+8) = ~270 minimum
        // Add breathing room for all screen sizes
        final cardHeight = cardWidth * 1.72;

        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: GridView.builder(
            itemCount: filteredProducts.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: cardWidth / cardHeight,
            ),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildProductCard(product);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 20),
            Image.asset("assets/images/wavy.webp", height: 45, width: 45),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "Hello, ",
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Lora',
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                      ),
                    ),
                    TextSpan(
                      text: isUserLoading ? "..." : userName,
                      style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'Lora',
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 40, right: 20, left: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff1D1616).withOpacity(0.11),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim();
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(15),
                  hintText: 'Search Electronics',
                  hintStyle: const TextStyle(
                    color: Color(0xffDDDADA),
                    fontSize: 18,
                  ),
                  prefixIcon: SizedBox(
                    width: 50,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/search.svg',
                        height: 30,
                        width: 30,
                      ),
                    ),
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close, color: Colors.grey),
                  )
                      : SizedBox(
                    width: 50,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/filter.svg',
                        height: 28,
                        width: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.green.shade500,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Recycle Your Device",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Book a pickup or drop it at one of our certified recycling centers",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecyclePage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Recycle Now",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                'Categories',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("categories")
                    .where("isActive", isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final categories = [
                    {"name": "All", "imagePath": ""},
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data["name"] ?? "").toString();
                      return {
                        "name": name,
                        "imagePath": (data["imagePath"] ?? "").toString(),
                      };
                    }).toList(),
                  ];

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: categories.length,
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = selectedCategory == category["name"];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = category["name"]!.toString();
                            });
                          },
                          child: Container(
                            width: 96,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.withOpacity(0.25)
                                  : Colors.green.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: _buildCategoryImage(
                                    (category["imagePath"] ?? "").toString(),
                                  ),
                                ),
                                Text(
                                  category["name"]!.toString(),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                searchQuery.isNotEmpty
                    ? 'Search Results'
                    : selectedCategory == "All"
                    ? 'Recommendation'
                    : '$selectedCategory Items',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("products")
                  .where("isActive", isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 30,
                    ),
                    child: Center(
                      child: Text(
                        "Something went wrong while loading products\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                final allProducts = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final parsedPrice = _parsePrice(data["price"]);

                  return {
                    "id": doc.id,
                    "imageUrl": (data["imageUrl"] ?? "").toString().trim(),
                    "title": (data["title"] ?? "").toString(),
                    "price": _formatIndianPrice(parsedPrice),
                    "priceRaw": parsedPrice,
                    "category": (data["category"] ?? "").toString(),
                    "description": (data["description"] ?? "").toString(),
                    "gradeLevel": (data["gradeLevel"] ?? "").toString(),
                    "inspectionHistory":
                    (data["inspectionHistory"] ?? "").toString(),
                  };
                }).toList();

                allProducts.sort((a, b) {
                  final titleA = (a["title"] ?? "").toString().toLowerCase();
                  final titleB = (b["title"] ?? "").toString().toLowerCase();
                  return titleA.compareTo(titleB);
                });

                final filteredProducts = _filterProducts(allProducts);

                if (filteredProducts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 30,
                    ),
                    child: Center(
                      child: Text(
                        searchQuery.isNotEmpty
                            ? "No matching products found"
                            : "No items found in this category yet",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                }

                return _buildResponsiveProductGrid(filteredProducts);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}