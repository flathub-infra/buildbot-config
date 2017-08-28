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
        <link href="http://flatpak.org/stylesheets/fonts.css" rel="stylesheet" />
        <link href="http://flatpak.org/stylesheets/site.css" rel="stylesheet" />
     </head>
      <body>
        <div class='appslist row'>
          <div class='col-xs-12'>
            <div class='row'>
              <h4 class='col-xs-12'>Applications</h4>
              <xsl:for-each select="component[starts-with(bundle, 'app/')]">
                <xsl:sort select="name"/>
                <div class='col-xs-12 col-sm-6 apptile'>
                  <img width="64" src="icons/64x64/{icon}"/>
                  <div>
                    <h4><xsl:value-of select="name"/></h4>
                    <p><xsl:value-of select="summary"/></p>
                  </div>
                  <a class="btn" href="../{substring-before(substring-after(bundle, 'app/'), '/')}.flatpakref"></a>
                </div>
              </xsl:for-each>
            </div>
          </div>
        </div>
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
