package com.apsit.canteen_management.config;

import com.apsit.canteen_management.security.AuthUtil;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.Nullable;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.scheduling.TaskScheduler;
import org.springframework.scheduling.concurrent.ThreadPoolTaskScheduler;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import java.nio.file.AccessDeniedException;
import java.util.Date;
import java.util.List;

@Configuration
@RequiredArgsConstructor
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final AuthUtil authUtil;

    // method to build a web socket connection. HANDSHAKE
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOrigins("http://localhost:*","http://127.0.0.1:*","https://apsit-canteen-admin-ui.vercel.app")
                .withSockJS();
    }

    // to configure the channels like /topic/order is the broadcast channel & /app for messages set from client to server.
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic","/queue")
                .setHeartbeatValue(new long[]{10000, 10000})
                .setTaskScheduler(heartBeatScheduler()); // heartbeat sends every 10 secs, expects every 10 secs.
        // if client doesn't response back with "pong" the SessionDisconnectEvent takes place. we can use that event for operations we want to perform.
        config.setApplicationDestinationPrefixes("/app");
        config.setUserDestinationPrefix("/user");
    }

    @Bean
    public TaskScheduler heartBeatScheduler(){
        ThreadPoolTaskScheduler scheduler=new ThreadPoolTaskScheduler();
        scheduler.setPoolSize(1);
        scheduler.setThreadNamePrefix("wss-heartbeat-");
        scheduler.initialize();
        return scheduler;
    }
    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new ChannelInterceptor() {
            @Override
            public @Nullable Message<?> preSend(Message<?> message, MessageChannel channel) {
                StompHeaderAccessor accessor= MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

                // authenticate when the client first connect
                assert accessor != null;
                if(StompCommand.CONNECT.equals(accessor.getCommand())){
                    String authHeader=accessor.getFirstNativeHeader("Authorization");
                    if(authHeader!=null && authHeader.startsWith("Bearer ")){
                        String jwtToken=authHeader.split("Bearer ")[1];
                        String username= authUtil.getUsernameFromToken(jwtToken);
                        if(username!=null){
                            List<GrantedAuthority> authorities=authUtil.getAuthoritiesFromToken(jwtToken);
                            UsernamePasswordAuthenticationToken authenticationToken=
                                    new UsernamePasswordAuthenticationToken(username,null, authorities);
                            accessor.setUser(authenticationToken);
                            Date expiresAt= authUtil.getExpireAtFromToken(jwtToken);
                            accessor.getSessionAttributes().put("jwt-expires-at",expiresAt.getTime());
                        }
                    }
                }else if(StompCommand.SEND.equals(accessor.getCommand()) || StompCommand.SUBSCRIBE.equals(accessor.getCommand())){
                    Long expiresAt= (Long) accessor.getSessionAttributes().get("jwt-expires-at");
                    if(expiresAt!=null && System.currentTimeMillis()>expiresAt){
                        try {
                            throw new AccessDeniedException("web socket token expired. Please reconnect!");
                        } catch (AccessDeniedException e) {
                            throw new RuntimeException(e);
                        }
                    }
                }
                return message;
            }
        });
    }
}
