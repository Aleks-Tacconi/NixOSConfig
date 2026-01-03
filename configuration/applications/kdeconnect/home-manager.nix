{ config, pkgs, lib, inputs, ... }:

{
  services.kdeconnect.enable = true;

  home.file.".local/share/applications/org.kde.kdeconnect.nonplasma.desktop".text =
    ''
      [Desktop Entry]
      Name=KDE Connect Indicator
      Name[en_GB]=KDE Connect Indicator
      Comment=Display information about your devices
      Comment[en_GB]=Display information about your devices
      Exec=kdeconnect-indicator
      Icon=kdeconnect
      Type=Application
      Terminal=false
      Categories=Qt;KDE;Network;
      NotShowIn=KDE;
      Name[en_GB.UTF-8]=KDE Connect Indicator
      X-GNOME-FullName[en_GB.UTF-8]=KDE Connect Indicator
      Comment[en_GB.UTF-8]=Display information about your devices
      NoDisplay=jpeg
      Path=
      X-GNOME-UsesNotifications=false
    '';

  home.file.".local/share/applications/org.kde.kdeconnect.sms.desktop".text = ''
    [Desktop Entry]
    Name=KDE Connect SMS
    Name[en_GB]=KDE Connect SMS
    GenericName=Text Messaging
    GenericName[en_GB]=Text Messaging
    Comment=Read and send SMS messages on connected devices
    Comment[en_GB]=Read and send SMS messages on connected devices
    Exec=kdeconnect-sms
    Icon=kdeconnect
    Type=Application
    Terminal=false
    Categories=Qt;KDE;InstantMessaging;Network;
    SingleMainWindow=true
    X-DBUS-StartupType=Unique
    X-DBUS-ServiceName=org.kde.kdeconnect.sms
    Name[en_GB.UTF-8]=KDE Connect SMS
    X-GNOME-FullName[en_GB.UTF-8]=KDE Connect SMS
    Comment[en_GB.UTF-8]=Read and send SMS messages on connected devices
    NoDisplay=true
    Path=
    X-GNOME-UsesNotifications=false
  '';
}
