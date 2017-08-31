<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl=
                "http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
              doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" indent="yes"/>

  <xsl:template match="/components">
    <html>
      <head>
        <title>Flathub apps</title>
        <link href="https://flathub.org/stylesheets/fonts-6c582ae6.css" rel="stylesheet" />
        <style>
body {
    font-family: 'Source Sans Pro', 'Source Sans', sans-serif;
    font-size: 13pt;
    font-weight: 400;
    font-style: normal;
}

h2 {
  font-size: 180%;
  font-weight: 300;
}

.apptile {
  display: flex;
  align-items: center;
  position: relative;
  min-height: 1px;
  padding-left: 15px;
  padding-right: 15px;
  float: left;
  width: calc(50% - 30px);
}

.apptile .icon {
  padding-right: 15px;
}

.apptile div {
  flex: 1;
}

.apptile h4 {
  font-size: 120%;
  font-weight: 300;
  color: #000;
  margin: 0;
}

.apptile p {
  font-size: 90%;
  font-weight: 300;
}

.apptile .btn {
  width: 32px;
  height: 32px;
  overflow: hidden;
  background: url("download.svg") no-repeat center;
}
        </style>
     </head>
      <body>
        <h2>Applications</h2>
        <xsl:for-each select="component[starts-with(bundle, 'app/')]">
          <xsl:sort select="name"/>
          <div class='apptile'>
            <img class="icon" width="64" src="icons/64x64/{icon}"/>
            <div>
              <h4><xsl:value-of select="name"/></h4>
              <p><xsl:value-of select="summary"/></p>
            </div>
            <a class="btn" href="../{substring-before(substring-after(bundle, 'app/'), '/')}.flatpakref"></a>
          </div>
        </xsl:for-each>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="component">
    <tr>
     <td><img src=".local/share/flatpak/appstream/flathub/x86_64/active/icons/64x64/{icon}"/></td>
     <td><xsl:value-of select="name"/></td>
     <td><xsl:value-of select="description"/></td>
    </tr>
  </xsl:template>

</xsl:stylesheet>
