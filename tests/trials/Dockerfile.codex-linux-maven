# todo-codex-linux-maven:0.167.0 with Maven and Java on the login-shell PATH. Codex runs agent commands with `bash -lc`,
# and Debian's /etc/profile resets PATH to /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin, which hides
# /usr/share/maven/bin and /opt/java/openjdk/bin (one of two concurrent lane workers got "mvn: command not found").
FROM todo-codex-linux-maven:0.167.0
RUN ln -s /usr/share/maven/bin/mvn /usr/local/bin/mvn \
 && for b in java javac; do ln -s "/opt/java/openjdk/bin/$b" "/usr/local/bin/$b"; done
