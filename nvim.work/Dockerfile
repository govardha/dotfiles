# Use the CentOS Stream 8 base image from Quay.io
FROM quay.io/centos/centos:stream8

# Update repository configuration to use vault.centos.org
RUN sed -i 's|mirrorlist=http://mirrorlist.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|^#.*baseurl=http|baseurl=http|g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|^mirrorlist=http|#mirrorlist=http|g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* && \
    dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled powertools

# Install the necessary build tools and dependencies for Neovim
RUN dnf update -y && \
    dnf groupinstall -y "Development Tools" && \
    dnf install -y \
        cmake \
        gcc-c++ \
        ninja-build \
        libtool \
        autoconf \
        automake \
        pkgconfig \
        unzip \
        patch \
        gettext \
        curl \
        git && \
    dnf clean all

# Set working directory
WORKDIR /build

# Clone Neovim source code
RUN git clone https://github.com/neovim/neovim.git .

# Build Neovim
RUN make CMAKE_BUILD_TYPE=RelWithDebInfo

# Install Neovim to /usr/local
RUN make install

# Create output directory for copying files
RUN mkdir -p /output

# Copy the nvim binary and its runtime files
RUN cp /usr/local/bin/nvim /output/nvim-binary && \
    cp -r /usr/local/share/nvim /output/nvim-runtime

# Show what libraries nvim depends on (for reference)
RUN echo "=== Neovim dependencies ===" && \
    ldd /usr/local/bin/nvim

# Create a non-root user for running nvim
RUN useradd -m -s /bin/bash nvimuser

# Switch to non-root user
USER nvimuser
WORKDIR /home/nvimuser

# Set the default command to run nvim
CMD ["nvim"]
