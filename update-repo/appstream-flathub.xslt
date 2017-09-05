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
        <link href="https://flathub.org/stylesheets/site-7c694642.css" rel="stylesheet" />
        <style>
          body { display: inline; }
        </style>
     </head>
      <body>
        <h2>Applications</h2>
        <xsl:for-each select="component[starts-with(bundle, 'app/')]">
          <xsl:sort select="name"/>
          <div class='col-sm-6 apptile'>
            <img width="64" height="64" src="icons/64x64/{icon}"/>
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
