<?xml version="1.0" encoding="UTF-8"?>
<!-- Basic MODS -->
<xsl:stylesheet version="1.0"
  xmlns:java="http://xml.apache.org/xalan/java"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:foxml="info:fedora/fedora-system:def/foxml#"
  xmlns:mods="http://www.loc.gov/mods/v3"
     exclude-result-prefixes="mods java">
  <!-- <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>-->
  <!--<xsl:include href="/usr/share/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/library/xslt-date-template.xslt"/>-->
  <!-- <xsl:include href="/vhosts/fedora/tomcat/webapps/fedoragsearch/WEB-INF/classes/config/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/> -->
  <xsl:include href="/usr/share/tomcat/webapps/fedoragsearch/WEB-INF/classes/fgsconfigFinal/index/FgsIndex/islandora_transforms/manuscript_finding_aid.xslt"/>
  <!-- HashSet to track single-valued fields. -->
  <xsl:variable name="single_valued_hashset" select="java:java.util.HashSet.new()"/>

  <xsl:template match="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]" name="index_MODS">
    <xsl:param name="content"/>
    <xsl:param name="prefix"></xsl:param>
    <xsl:param name="suffix">ms</xsl:param>

    <!-- Clearing hash in case the template is ran more than once. -->
    <xsl:variable name="return_from_clear" select="java:clear($single_valued_hashset)"/>

    <!--
      creates a mode for MODS records that do *not* have a mods:identifer starting with 'utk_' *AND* do *not* have a
      mods:genre = 'Academic theses'.
    -->
    <xsl:apply-templates mode="utk_MODS" select="$content//mods:mods[1]"/>
  </xsl:template>
  
  <!--
    additional templating for our MODS name/roles and geographic terms/coordinates
  -->
  <!-- the following template creates an _ms name+role field -->
  <xsl:template match="mods:mods/mods:name" mode="utk_MODS">
    <xsl:variable name="vName" select="child::mods:namePart[not(@type)]"/>
    <xsl:variable name="vRole">
      <xsl:if test="child::mods:role/mods:roleTerm">
        <xsl:text>(</xsl:text>
        <xsl:for-each select="child::mods:role/mods:roleTerm">
          <xsl:value-of select="normalize-space(.)"/>
          <xsl:if test="not(position()=last())">,</xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="vDate">
      <xsl:if test="child::mods:namePart[@type='date']">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="child::mods:namePart[@type='date']"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="vDescription">
      <xsl:if test="child::mods:description">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="child::mods:description"/>
      </xsl:if>
    </xsl:variable>

    <field name="utk_mods_name_role_ms">
      <xsl:choose>
        <xsl:when test="$vRole=''">
          <xsl:value-of select="concat($vName,$vDate,$vDescription)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($vName,$vDate,$vDescription,' ',$vRole)"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>

  <!-- the following template creates a geoSubject+coordinates _ms field or just geoSubject_ms field-->
  <xsl:template match="mods:mods/mods:subject[mods:geographic]" mode="utk_MODS">
    <xsl:variable name="vGeo" select="child::mods:geographic"/>
    <xsl:variable name="vCoords" select="child::mods:cartographics/mods:coordinates"/>
    <field name="utk_mods_geo_ms">
      <xsl:choose>
        <xsl:when test="$vCoords!=''">
          <xsl:value-of select="concat($vGeo,' ','(',$vCoords,')')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$vGeo"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>
  
  <xsl:template match="mods:mods/mods:originInfo/mods:dateCreated[@encoding='edtf']" mode="utk_MODS">
    <xsl:variable name="decade" select="substring(., 1, 3)"/>
    <field name="utk_mods_dateCreated_decade_ms">
          <xsl:value-of select="concat($decade, '0s')"/>
    </field>
  </xsl:template>
  
  <!-- the following template creates a Supplied Title field -->
  <xsl:template match="mods:mods/mods:titleInfo[@supplied='yes']/mods:title" mode="utk_MODS">
    <field name="utk_mods_supplied_title_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- the following template creates an archivalCollection+archivalIdentifier _ms field -->
  <xsl:template match="mods:mods/mods:relatedItem[@type='host'][@displayLabel='Collection']" mode="utk_MODS">
    <xsl:variable name="vColl" select="child::mods:titleInfo/mods:title"/>
    <xsl:variable name="vArchivalID">
      <xsl:if test="child::mods:identifier[@type='local']">
        <xsl:value-of select="child::mods:identifier"/>
      </xsl:if>
    </xsl:variable>

    <field name="utk_mods_archColl_archID_ms">
      <xsl:choose>
        <xsl:when test="$vArchivalID=''">
          <xsl:value-of select="$vColl"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($vColl,', ',$vArchivalID)"/>
        </xsl:otherwise>
      </xsl:choose>
    </field>
  </xsl:template>
  
  <!-- the following template creates a UTK MODS Related Work Field -->
  <xsl:template match="mods:mods/mods:relatedItem[@type='otherVersion']" mode="utk_MODS">
    <xsl:variable name="related_work" select="child::mods:titleInfo/mods:title"/>
    <field name="utk_mods_relate_work_ms">
      <xsl:value-of select="$related_work"/>
    </field>
  </xsl:template>
  

  <!-- subjects! -->
  <!-- the following template creates a simplified topical subject _ms field -->
  <!--
    note: this is *very* generic; it grabs all mods:subjects with an @authority,
    so we may want to add some specificity in here at some point. maybe.
  -->
  <xsl:template match="mods:mods/mods:subject[@authority]" mode="utk_MODS">
    <!--
       dots = Database of the Smokies
       lcsh = Library of Congress
       fast = FAST
       local = Local Thang
     -->
    <xsl:variable name="vAuthority">
      <xsl:choose>
        <xsl:when test="self::node()/@authority='dots'">
          <xsl:value-of select="', (Database of the Smokies)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='lcsh'">
          <xsl:value-of select="', (Library of Congress Subject Headings)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='fast'">
          <xsl:value-of select="', (FAST)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='local'">
          <xsl:value-of select="', (Local Subject Heading)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='naf'">
          <xsl:value-of select="', (Library of Congress Name Authority File)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='tgm'">
          <xsl:value-of select="', (Library of Congress Thesaurus for Graphic Materials)'"/>
        </xsl:when>
        <xsl:when test="self::node()/@authority='agrovoc'">
          <xsl:value-of select="', (AGROVOC)'"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <field name="utk_mods_subject_topic_ms">
      <xsl:value-of select="normalize-space(concat(child::mods:topic, $vAuthority))"/>
    </field>
  </xsl:template>

  <!-- the following templates creates a simplified Volunteer Voices subject _ms field -->
  <!--
    one for each:
    Volunteer Voices Curriculum Topics
    Broad Topics
    Tennessee Social Studies K-12 Eras in American History
  -->
  <xsl:template match="mods:mods/mods:subject[@displayLabel='Volunteer Voices Curriculum Topics']" mode="utk_MODS">
    <field name="utk_mods_subject_topic_curriculumTopics_ms">
      <xsl:value-of select="normalize-space(concat(.,' ','(','Volunteer Voices',')'))"/>
    </field>
  </xsl:template>
  <xsl:template match="mods:mods/mods:subject[@displayLabel='Broad Topics']" mode="utk_MODS">
    <field name="utk_mods_subject_topic_broadTopics_ms">
      <xsl:value-of select="normalize-space(concat(.,' ','(','Volunteer Voices',')'))"/>
    </field>
  </xsl:template>
  <xsl:template match="mods:mods/mods:subject[@displayLabel='Tennessee Social Studies K-12 Eras in American History']"
                mode="utk_MODS">
    <field name="utk_mods_subject_topic_socStudiesK12_ms">
      <xsl:value-of select="normalize-space(concat(.,' ','(','Volunteer Voices',')'))"/>
    </field>
  </xsl:template>

  <!-- the following template creates an _ms field for accessCondition+attributes -->
  <xsl:template match="mods:mods/mods:accessCondition[@type='use and reproduction']">
    <field name="utk_mods_accessCondition_ms">
      <xsl:value-of select="normalize-space(concat(.,' ','(','useAndReproduction',')'))"/>
    </field>
  </xsl:template>

  <!-- the following template creates an _ms field for abstract(s) -->
  <!-- pulls all all mods:abstracts into one _ms field. maybe overly greedy? -->
  <xsl:template match="mods:mods/mods:abstract" mode="utk_MODS">
    <field name="utk_mods_abstract_ms">
      <xsl:for-each select=".">
        <xsl:value-of select="concat(.,' ')"/>
      </xsl:for-each>
    </field>
  </xsl:template>
  
  <!-- Build instrumentation facet. -->
  <xsl:template match="mods:mods/mods:note[@type='instrumentation']" mode="utk_MODS">
    <field name="utk_mods_note_instrumentation_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- add a tableOfContents field -->
  <xsl:template match="mods:mods/mods:tableOfContents" mode="utk_MODS">
    <field name="utk_mods_toc_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- add mods_abstract_ms -->
  <xsl:template match="mods:mods/mods:abstract" mode="utk_MODS">
    <field name="mods_abstract_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>

  <!-- add mods_identifier_local_ms -->
  <xsl:template match="mods:mods/mods:identifier[@type='local']">
    <field name="mods_identifier_local_ms">
      <xsl:value-of select="normalize-space(.)"/>
    </field>
  </xsl:template>


</xsl:stylesheet>
