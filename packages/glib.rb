class Glib < PACKMAN::Package
  url 'http://ftp.gnome.org/pub/gnome/sources/glib/2.40/glib-2.40.0.tar.xz'
  sha1 '44e1442ed4d1bf3fa89138965deb35afc1335a65'
  version '2.40.0'

  depends_on 'pkgconfig'
  depends_on 'gettext'
  depends_on 'libffi'

  patch do
    url 'https://gist.githubusercontent.com/jacknagel/af332f42fae80c570a77/raw/a738786e0f7ea46c4a93a36a3d9d569017cca7f2/glib-hardcoded-paths.diff'
    sha1 'ce54abdbb4386902a33dbad7cb6c8f1b0cbdab0d'
  end

  patch do
    url 'https://gist.githubusercontent.com/jacknagel/9835034/raw/b0388e86f74286f4271f9b0dca8219fdecafd5e3/gio.patch'
    sha1 '32158fffbfb305296f7665ede6185a47d6f6b389'
  end

  def install
    # Disable dtrace; see https://trac.macports.org/ticket/30413
    args = %W[
      --prefix=#{prefix}
      --disable-maintainer-mode
      --disable-dependency-tracking
      --disable-silent-rules
      --disable-dtrace
      --disable-libelf
    ]
    PACKMAN.set_cppflags_and_ldflags [Gettext, Libffi]
    PACKMAN.run './configure', *args
    PACKMAN.run 'make -j2'
    # PACKMAN.run 'ulimit -n 1024; make check'
    PACKMAN.run 'make install'

    PACKMAN.replace "#{lib}/pkgconfig/glib-2.0.pc", {
      /(Libs: -L\$\{libdir\} -lglib-2.0) (-lintl)/ => "\\1 -L#{Gettext.lib} \\2",
      /(Cflags: -I\$\{includedir\}\/glib-2.0 -I\$\{libdir\}\/glib-2.0\/include)/ => "\\1 -I#{Gettext.include}"
    }
  end
end
