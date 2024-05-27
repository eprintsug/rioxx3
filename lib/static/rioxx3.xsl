<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:rioxx="http://www.rioxx.net/schema/v3.0/rioxx/"
  xmlns:rioxxterms="http://www.rioxx.net/schema/v3.0/rioxxterms/"
>

<!-- <xsl:output method="html" doctype-system="about:legacy-compat"/> -->
<xsl:output method="html" omit-xml-declaration="yes"/>

<xsl:template match="/">
        <xsl:apply-templates/>
</xsl:template>

<xsl:template match="rioxxterms:*">
</xsl:template>
<xsl:template match="rioxxterms:record_public_release_date">
  <p>Blah</p>
</xsl:template>

<xsl:template match="rioxx">
  <div class="rioxx3_metadata">
    <table>
      <thead>
        <tr>
          <th>Element</th>
          <th>Value</th>
          <th>XML</th>
        </tr>
      </thead>
      <tbody>
      <xsl:if test="not(rioxxterms:creator)">
        <tr><td colspan="3" class="missing">NO rioxxterms:creator. THERE MUST BE AT LEAST ONE!</td></tr>  
      </xsl:if>
        <xsl:for-each select="*">
          <tr>
            <td><xsl:value-of select="name()"/></td>
            <td><xsl:value-of select="."/></td>
            <td class="xml" style="font-family: monospace"><xsl:copy-of select="."/></td>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </div>
</xsl:template>

</xsl:stylesheet>

