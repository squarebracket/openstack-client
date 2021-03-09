ARG centos_version=7
FROM centos:${centos_version}
ARG openstack_release=queens
RUN \
  if ! yum -q list "centos-release-openstack-${openstack_release}" >/dev/null 2>/dev/null; then \
      VAULT_VERSION="$(\
          yum -q list --enablerepo='C7*-extras' --show-duplicates \
              "centos-release-openstack-$openstack_release" 2>/dev/null | \
          sed -nE "s|^centos-release-openstack-$openstack_release.*\s+C(7.*)-extras|\1|p" | \
          sort | \
          tail -1 \
      )"; \
      if [ -z "$VAULT_VERSION" ]; then \
          echo "OpenStack release '$openstack_release' not found" >&2 && \
          exit 1; \
      fi; \
      yum-config-manager -q --enable "C${VAULT_VERSION}*" >/dev/null; \
  fi; \
  yum install -y "centos-release-openstack-${openstack_release}" && \
  REPO_URL_FIND="http://mirror.centos.org/centos/(\\\$releasever|7)/" && \
  REPO_URL_REPLACE="https://archive.kernel.org/centos-vault/$VAULT_VERSION/" && \
  for repo in $(yum -q --disablerepo='*' list installed 'centos-release-*' | \
          sed -nE 's/centos-release-([[:alpha:]-]+).*/\1/p'); do \
      if yum repolist 2>/dev/null | grep "centos-$repo" &>/dev/null && \
              ! yum list available --disablerepo='*' --enablerepo="centos-$repo" &>/dev/null; then \
          REPO_FILE="$(rpm -ql "centos-release-$repo" | grep '\.repo')" && \
          sed -E -i "s#$REPO_URL_FIND#$REPO_URL_REPLACE#g" "$REPO_FILE"; \
      fi; \
  done

# yum randomly fails sometimes, so just try 3 times
RUN yum install -y python*-openstackclient python*-heatclient || \
    yum install -y python*-openstackclient python*-heatclient || \
    yum install -y python*-openstackclient python*-heatclient

ENTRYPOINT ["openstack"]
