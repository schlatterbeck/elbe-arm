Image builder for Common ARM boards
===================================

This package asumes a Debian installation and uses the Embedded Linux
Build Environment (ELBE) für building custom images for many ARM based
board. ELBE uses a KVM virtual machine for the whole build environment.
Inside this machine a QEMU istance is run for the target architecture.
The image is built from a standard debian repository. This ensures that
the resulting image always has the latest debian packages with security
fixes. Note that ELBE provides for building reproduceable images that
contain the same packages even if newer packages are available from the
distribution. For more details on ELBE see `ELBE's website`_ and
`ELBE's git`_.

.. _`ELBE's website`: https://elbe-rfs.org/
.. _`ELBE's git`: https://github.com/Linutronix/elbe

Prerequisites
-------------

You need to work on an existing Debian Linux machine. I've tested this
on an AMD64 architecture but this should work on other architectures,
too.

You need to put the ELBE repositories into your
``/etc/apt/sources.list`` or into the ``sources.list.d`` directory::

  # ELBE
  deb http://debian.linutronix.de/elbe stretch main
  deb http://debian.linutronix.de/elbe-common stretch main

The Linux kernel and the U-Boot bootloader are built on the local
machine (not inside the ELBE VM), maybe at some later time I'll support
building natively on ELBE. For this reason you need to install an ARMHF
cross-compiler which is provided by debian::

  apt-get install gcc-arm-linux-gnueabihf

You probably need some more tools installed via debian, currently I've
not tracked all the packages you need.

You also need a checkout of the latest U-Boot release from Denx::

  git://git.denx.de/u-boot.git

and a recent Linux version, either mainline from Linus or the stable
series from Greg, note that some of the boards only gained support in
Kernels as recent as 4.15::

  git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
  git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

In most cases you want to explicitly check out a tagged release version
for both, Linux, and the U-Boot bootloader. We asume you're familiar
enough with Git to do this.

The locations of these checkouts need to be either set as
environment-variables or specified as ``KERNEL`` and ``BOOTLOADER``
parameters during ``make`` invocation if the defaults at the top of the
``Makefile`` don't suit you.

Note that we currently use a single kernel for all boards. During kernel
build an existing kernel configuration in a ``.config`` file is
overwritten with the checked-in kernel-config file. Also a ``distclean``
is performed to get rid of automatic compile-counting of the standard
kernel.

To compile for a specific board, the board name from U-Boot is used. See
the Makefile for the currently-supported boards. Note that the only
dependency in the Makefile on the board names is currently the name of
the DTB-File to use for the board: The DTB is set in the Makefile
depending on the target board. The board name is specified with the
TARGET environment variable or ``Makefile`` parameter. Since U-Boot also
contains a mechanism for computing the name of the DTB, we may use the
same mechanism in the future.

If you need to use your own DTB-File, you should make sure the source is
in the used kernel sources and it is built during kernel build, because
the DTB is copied from the kernel package to ``/boot`` on the resulting
image. You can override the automagic computation of the DTB-File by
specifying a ``DTB=`` parameter to ``make`` or setting the ``DTB``
environment variable.

Special Hacks
-------------

This package uses some special hacks to allow a custom-built bootloader
and a custom-built Debian kernel-package to be used with ELBE. ELBE
supports only signed repositories currently. So this project sets up a
signed repository with a throwaway GPG key. Then it starts a Webserver
in the local directory (using python's built-in webserver) on a
configurable port (9090 by default). This webserver might pose a
security risk and you should be able to kill it using ``make clean``.
Alternatively, if that doesn't work and you want to be sure no server is
running you should look for a process with the command-line similar to
the following (the port might differ if you have changed it)::

  python -m SimpleHTTPServer 9090

For the local debian repository with the kernel packages you want to set
the debian maintainer settings for the built debian source package::

  export DEBEMAIL="your@email.address"
  export DEBFULLNAME="Your Name"

These are used for signing the packages and are also used in the
generated temporary GPG key.

Bugs
----

Currently the ELBE *finetuning* mechanism doesn't allow me to delete
the bootloader file: The bootloader is written to a special section on
the generated SD-Card image. It is not needed in the filesystem. So you
can safely remove the ``/u-boot.bin`` file in the resulting image.
