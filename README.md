# MakOS
"MacOS at home"

**MakOS** is intended to be a MacOS alike distro made by someone who has never used MacOS but loves the architecture.

It is a GNOME desktop built on [Universal Blue](https://universal-blue.org/)'s base image, with GNOME installed by the image build. It ships [Bazaar](https://flathub.org/apps/io.github.kolunmi.Bazaar) as the app store and preinstalls [Gear Lever](https://flathub.org/apps/it.mijorus.gearlever) for managing AppImages. (I don't see alot of distros packaging this and i dont know why! It's GREAT!)

Because **MakOS** is entirely reliant on upstream (it's just fedora silver blue with a couple preinstalled packages) you can expect it to *just work*!

This repository started from the [Universal Blue image template](https://github.com/ublue-os/image-template).

The installer ISO is a Bazzite-style live MakOS environment with Anaconda Web UI. See [`installer/README.md`](installer/README.md) for build details.