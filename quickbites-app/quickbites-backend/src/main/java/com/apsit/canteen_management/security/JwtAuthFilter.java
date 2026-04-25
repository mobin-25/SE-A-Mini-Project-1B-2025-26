package com.apsit.canteen_management.security;

// To use make use of jwt token in future after it once get generated while login.

import com.apsit.canteen_management.entity.Admin;
import com.apsit.canteen_management.entity.User;
import com.apsit.canteen_management.repository.AdminRepository;
import com.apsit.canteen_management.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.HandlerExceptionResolver;

import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final UserRepository userRepository;
    private final AuthUtil authUtil;
    private final AdminRepository adminRepository;

    private final HandlerExceptionResolver handlerExceptionResolver;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        try {
            final String requestTokenHeader = request.getHeader("Authorization");
            if (requestTokenHeader == null || !requestTokenHeader.startsWith("Bearer")) {
                filterChain.doFilter(request, response);
                return;
            }
            String token = requestTokenHeader.split("Bearer ")[1];
        /*
         "Bearer" is used in Authorization as a key which tell that this is a token which user holds
         so that server knows which way do the client wants to authorize himself.
         Note-: since "Bearer " is just a key not the part of actual token and space is seperator, we have to extract
         the legit token form it. So that we can either split the key and token or just take substring like token.substring(8)
         */
            String username = authUtil.getUsernameFromToken(token);
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                User user = userRepository.findByUsername(username).orElse(null);
                if (user != null) {
                    UsernamePasswordAuthenticationToken authToken =
                            new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                } else {
                    Admin admin = adminRepository.findByUsername(username)
                            .orElseThrow(() -> new UsernameNotFoundException("No account found for: " + username));
                    UsernamePasswordAuthenticationToken authToken =
                            new UsernamePasswordAuthenticationToken(
                                    admin, null,
                                    List.of(new SimpleGrantedAuthority("ROLE_" + admin.getRole().name()))
                            );
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            }
            filterChain.doFilter(request, response);
        }catch (Exception e){
            handlerExceptionResolver.resolveException(request, response, null, e);
            /* although we made exception handler in global exception handler but still we won't be able to use them
             So here is the concept of layering spring boot.
             the global exception handler handles only the exceptions which are thrown from our controller layer
             But since JwtAuthFilter is a filter therefore it throws error way before getting into the controller layer
             where spring actrually dones'nt know how to handle it therefore we manualy push the excpetion to out
             global exception handler using HandlerExceptionResolver.
             */
        }
    }
}
