<project>
  <name>elbe-sunxi</name>
  <version>1.0</version>
  <description>
    For Olimex and Banana-Pi Boards
  </description>
  <buildtype>armhf</buildtype>
  <mirror>
    <primary_host>bee.priv.zoo</primary_host>
    <primary_path>/debian</primary_path>
    <primary_proto>http</primary_proto>
    <url-list>
      <url>
        <binary>
          http://debian.linutronix.de/elbe-testing stretch main
        </binary>
        <key>
          http://debian.linutronix.de/elbe/elbe-repo.pub
        </key>
      </url>
      <url>
        <binary>
          http://debian.linutronix.de/elbe-common stretch main
        </binary>
        <key>
          http://debian.linutronix.de/elbe/elbe-repo.pub
        </key>
      </url>
