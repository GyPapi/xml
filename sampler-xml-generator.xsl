<?xml version="1.0" encoding="UTF-8"?>
<!-- 
  Sampler XML generator

  Generic XML sample generator, based on an XML Schema (xsd).
  Targeted at version 1.0, no extensions added or expected (MSXML6 should be able to use the stylesheet).

  Receives as the input an XML Schema (or an XML document that hosts an XML Schema, like a WSDL).
  Creates an XML document that can be edited before full validation.

  Work in progress.

  Notable missing points:
  * many XML Schema types not yet covered
  * a few XML Schema elements not yet covered

  Notable constraints:
  * main or imported schema should declare targetNamespace: that's on what the generator depends to determine the schema elements' namespace
  * no rules
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" version="1.0">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <!-- parameters that govern the sampling process -->

  <!-- leave blank for first schema defined in the document -->
  <xsl:param name="sampleNamespace"></xsl:param>

  <!-- leave blank for first element defined in the schema -->
  <xsl:param name="sampleRootElement"></xsl:param>

  <!-- y/n to generate optional elements and attributes -->
  <xsl:param name="sampleOptionalElements">y</xsl:param>
  <xsl:param name="sampleOptionalAttributes">y</xsl:param>

  <!-- y/n to generate comments from the annotations -->
  <xsl:param name="sampleComments">y</xsl:param>

  <!-- what unbounded means: a (probably) small number -->
  <xsl:param name="sampleUnbounded">2</xsl:param>

  <!-- in choice groups, fetch the elements in "sequence", or always the "first", or "comment" all others -->
  <xsl:param name="sampleChoiceStrategy">sequence</xsl:param>

  <!-- y/n to show the restricted string length -->
  <xsl:param name="sampleStringLength">n</xsl:param>

  <!-- generate strings based on the "default" setting, or on the element/attribute "name"  -->
  <xsl:param name="sampleStringSource">name</xsl:param>

  <!-- y/n to sample patterns -->
  <xsl:param name="samplePattern">y</xsl:param>

  <!-- y/n to sample Boolean as a number 1/0 -->
  <xsl:param name="sampleBooleanAsNumber">n</xsl:param>

  <!-- y/n to sample URI as http address -->
  <xsl:param name="sampleURIasHTTP">y</xsl:param>

  <!-- the default value for a string -->
  <xsl:param name="sampleDefaultString">string</xsl:param>

  <!-- the default value for a number -->
  <xsl:param name="sampleDefaultNumber">0</xsl:param>

  <!-- the default value for dates -->
  <xsl:param name="sampleDefaultDate">2017-01-01T12:00:00</xsl:param>

  <!-- the default value for untyped text data -->
  <xsl:param name="sampleDefaultTextData">text data</xsl:param>

  <!-- the default value for boolean -->
  <xsl:param name="sampleDefaultBoolean">true</xsl:param>

  <!-- the default values for binary data (encoding of the string "binary data")  -->
  <xsl:param name="sampleDefaultBase64Binary">YmluYXJ5IGRhdGE=</xsl:param>
  <xsl:param name="sampleDefaultHexBinary">62696E6172792064617461</xsl:param>

  <!-- the default value for URI -->
  <xsl:param name="sampleDefaultURI">URI:#</xsl:param>

  <!-- the default value for http URI -->
  <xsl:param name="sampleDefaultHTTP">http://www.example.com</xsl:param>

  <!-- the default value for xml:space attribute value -->
  <xsl:param name="sampleDefaultXMLSpace">default</xsl:param>

  <!-- the default value for xml:lang attribute value -->
  <xsl:param name="sampleDefaultXMLLang">en</xsl:param>

  <!-- the default value for xml:base attribute value -->
  <xsl:param name="sampleDefaultXMLBase">http://www.example.com</xsl:param>

  <!-- fetch and store the target namespace of the main schema -->
  <xsl:variable name="namespace">
    <xsl:choose>
      <xsl:when test="$sampleNamespace = ''">
        <xsl:variable name="tns">
          <xsl:call-template name="getTargetNamespace"/>
        </xsl:variable>
        <xsl:value-of select="substring-before($tns, '&#x09;')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleNamespace"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!--
    locate the target namespace when not given as a sampler argument
  -->
  <xsl:template name="getTargetNamespace">
    <xsl:choose>
      <!-- the target element is found in the current schema -->
      <xsl:when test="//xs:schema[1]/xs:element[@name = $sampleRootElement]">
        <xsl:value-of select="concat(//xs:schema[1]/@targetNamespace, '&#x09;')"/>
      </xsl:when>
      <!-- in case there are no elements in the current schema, check for target namespace in imported schemas -->
      <xsl:when test="not(//xs:schema[1]/xs:element)">
        <xsl:for-each select="//xs:schema[1]/xs:import">
          <xsl:for-each select="document(@schemaLocation)">
            <xsl:call-template name="getTargetNamespace" />
          </xsl:for-each>
        </xsl:for-each>
      </xsl:when>
      <!-- if an element was given, and not found, and there are imported schemas, look for the element in these schemas -->
      <xsl:when test="$sampleRootElement != '' and //xs:schema[1]/xs:import">
        <xsl:for-each select="//xs:schema[1]/xs:import">
          <xsl:for-each select="document(@schemaLocation)">
            <xsl:call-template name="getTargetNamespace" />
          </xsl:for-each>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <!-- if the root element was not given, set the target namespace to the first schema's -->
        <xsl:value-of select="concat(//xs:schema[1]/@targetNamespace, '&#x09;')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- get the prefix associated to a particular namespace -->
  <xsl:template name="getPrefix">
    <xsl:param name="namespace"/>

    <xsl:value-of select="name(ancestor-or-self::*/namespace::*[. = $namespace])"/>
  </xsl:template>

  <!-- string types -->
  <xsl:variable name="xsID">ID</xsl:variable>
  <xsl:variable name="xsIDREF">IDREF</xsl:variable>
  <xsl:variable name="xsString">string</xsl:variable>
  <xsl:variable name="xsLanguage">language</xsl:variable>
  <xsl:variable name="xsToken">token</xsl:variable>
  <xsl:variable name="xsNormalizedString">normalizedString</xsl:variable>

  <!-- numeric types -->
  <xsl:variable name="xsByte">byte</xsl:variable>
  <xsl:variable name="xsDecimal">decimal</xsl:variable>
  <xsl:variable name="xsInt">int</xsl:variable>
  <xsl:variable name="xsInteger">integer</xsl:variable>
  <xsl:variable name="xsLong">long</xsl:variable>
  <xsl:variable name="xsNegativeInteger">negativeInteger</xsl:variable>
  <xsl:variable name="xsNonNegativeInteger">nonNegativeInteger</xsl:variable>
  <xsl:variable name="xsNonPositiveInteger">nonPositiveInteger</xsl:variable>
  <xsl:variable name="xsPositiveInteger">positiveInteger</xsl:variable>
  <xsl:variable name="xsShort">short</xsl:variable>
  <xsl:variable name="xsUnsignedByte">unsignedByte</xsl:variable>
  <xsl:variable name="xsUnsignedInt">unsignedInt</xsl:variable>
  <xsl:variable name="xsUnsignedLong">unsignedLong</xsl:variable>
  <xsl:variable name="xsUnsignedShort">unsignedShort</xsl:variable>

  <!-- date types -->
  <xsl:variable name="xsDate">date</xsl:variable>
  <xsl:variable name="xsDateTime">dateTime</xsl:variable>

  <!-- boolean -->
  <xsl:variable name="xsBoolean">boolean</xsl:variable>

  <!-- binary -->
  <xsl:variable name="xsBase64Binary">base64Binary</xsl:variable>
  <xsl:variable name="xsHexBinary">hexBinary</xsl:variable>

  <!-- URI -->
  <xsl:variable name="xsAnyURI">anyURI</xsl:variable>

  <!-- convenient reference to types, grouped by base type -->
  <xsl:variable name="xsGroupString">
    <xsl:value-of select="concat('|', $xsID)"/>
    <xsl:value-of select="concat('|', $xsIDREF)"/>
    <xsl:value-of select="concat('|', $xsString)"/>
    <xsl:value-of select="concat('|', $xsLanguage)"/>
    <xsl:value-of select="concat('|', $xsNormalizedString)"/>
    <xsl:value-of select="concat('|', $xsToken, '|')"/>
  </xsl:variable>
  <xsl:variable name="xsGroupNumeric">
    <xsl:value-of select="concat('|', $xsByte)"/>
    <xsl:value-of select="concat('|', $xsDecimal)"/>
    <xsl:value-of select="concat('|', $xsInteger)"/>
    <xsl:value-of select="concat('|', $xsInt)"/>
    <xsl:value-of select="concat('|', $xsLong)"/>
    <xsl:value-of select="concat('|', $xsPositiveInteger)"/>
    <xsl:value-of select="concat('|', $xsNonPositiveInteger)"/>
    <xsl:value-of select="concat('|', $xsNegativeInteger)"/>
    <xsl:value-of select="concat('|', $xsNonNegativeInteger)"/>
    <xsl:value-of select="concat('|', $xsShort)"/>
    <xsl:value-of select="concat('|', $xsUnsignedByte)"/>
    <xsl:value-of select="concat('|', $xsUnsignedInt)"/>
    <xsl:value-of select="concat('|', $xsUnsignedLong)"/>
    <xsl:value-of select="concat('|', $xsUnsignedShort, '|')"/>
  </xsl:variable>
  <xsl:variable name="xsGroupDate">
    <xsl:value-of select="concat('|', $xsDate)"/>
    <xsl:value-of select="concat('|', $xsDateTime, '|')"/>
  </xsl:variable>
  <xsl:variable name="xsGroupBinary">
    <xsl:value-of select="concat('|', $xsBase64Binary)"/>
    <xsl:value-of select="concat('|', $xsHexBinary, '|')"/>
  </xsl:variable>
  
  <!--
    the main template: locate the root element, as given by the parameters or default, and start the sampling from there
  -->
  <xsl:template match="/" name="root">

    <xsl:choose>

      <!-- the given root element is found in one of the currently visible schemas -->
      <xsl:when test="//xs:schema[@targetNamespace = $sampleNamespace or $sampleNamespace = '']/xs:element[@name = $sampleRootElement]">
        <xsl:for-each select="(//xs:schema[@targetNamespace = $sampleNamespace or $sampleNamespace = '']/xs:element[@name = $sampleRootElement])[1]">
          <xsl:call-template name="element">
            <xsl:with-param name="root" select="true()"/>
            <xsl:with-param name="tree" select="''"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <!-- there is no given root element, and there is at least one element in the currently visible schemas -->
      <xsl:when test="$sampleRootElement = '' and //xs:schema[@targetNamespace = $sampleNamespace or $sampleNamespace = '']/xs:element[1]">
        <xsl:for-each select="(//xs:schema[@targetNamespace = $sampleNamespace or $sampleNamespace = '']/xs:element[1])[1]">
          <xsl:call-template name="element">
            <xsl:with-param name="root" select="true()"/>
            <xsl:with-param name="tree" select="''"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <xsl:otherwise>
        <!-- in case there are no elements in the current schemas, look for them in the imported schemas -->
        <xsl:call-template name="findInImported">
          <xsl:with-param name="schemas" select="//xs:schema/xs:import"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- when the root element is not found in the current visible schema(s), the tree of imported schemas may be fully
        traversed to look for it -->
  <xsl:template name="findInImported">
    <!-- the node list of imported schemas, at a given level -->
    <xsl:param name="schemas" />
    <!-- an iterator to go through the node list -->
    <xsl:param name="index" select="1"/>

    <!-- a convenient pointer to an imported schema -->
    <xsl:variable name="schema" select="document($schemas[$index]/@schemaLocation)/xs:schema"/>

    <xsl:choose>

      <!-- found a given root element? sample it and stop the imported schemas search -->
      <xsl:when test="$schema[@targetNamespace = $sampleNamespace or $sampleNamespace = '']/xs:element[@name = $sampleRootElement]">
        <xsl:for-each select="($schema[@targetNamespace = $sampleNamespace or $sampleNamespace = '']/xs:element[@name = $sampleRootElement])[1]">
          <xsl:call-template name="element">
            <xsl:with-param name="root" select="true()"/>
            <xsl:with-param name="tree" select="''"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <!-- when no given root element, and found an element definition? sample it and stop -->
      <xsl:when test="$sampleRootElement = '' and $schema[@targetNamespace = $sampleNamespace or $sampleNamespace = '']/xs:element[1]">
        <xsl:for-each select="($schema[@targetNamespace = $sampleNamespace or $sampleNamespace = '']/xs:element[1])[1]">
          <xsl:call-template name="element">
            <xsl:with-param name="root" select="true()"/>
            <xsl:with-param name="tree" select="''"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <!-- if there are other schemas imported by the one we are investigating, go deeper in the tree -->
      <xsl:when test="$schema/xs:import">
        <xsl:call-template name="findInImported">
          <xsl:with-param name="schemas" select="$schema/xs:import"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <!-- check the new schema in the node list, until the list is exhausted -->
        <xsl:if test="$index &lt; count($schemas)">
          <xsl:call-template name="findInImported">
            <xsl:with-param name="schemas" select="$schemas"/>
            <xsl:with-param name="index" select="$index + 1"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--

    include* (Elements, Attributes, ComplexTypes, SimpleTypes, Groups, AttributeGroups)

    these templates look for references in included or imported schemas
    at the main schema, and then (recursively) in all linked schemas (by inclusion or importing)

    the namespace may be set differently, in these linked schemas (that's what is expected with imported schemas)
  -->
  <xsl:template name="includeElements">
    <xsl:param name="elementRef"/>
    <xsl:param name="root" select="false()"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="targetNS"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:element[@name = $elementRef and $includeNamespace = $targetNS]">
            <xsl:for-each select="xs:element[@name = $elementRef and $includeNamespace = $targetNS]">
              <xsl:call-template name="element">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="root" select="$root"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="commented" select="$commented"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeElements">
              <xsl:with-param name="elementRef" select="$elementRef"/>
              <xsl:with-param name="root" select="$root"/>
              <xsl:with-param name="commented" select="$commented"/>
              <xsl:with-param name="tree" select="$tree"/>
              <xsl:with-param name="targetNS" select="$targetNS"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeAttributes">
    <xsl:param name="attribRef"/>
    <xsl:param name="targetNS"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:attribute[@name = $attribRef and $includeNamespace = $targetNS]">
            <xsl:for-each select="xs:attribute[@name = $attribRef and $includeNamespace = $targetNS]">
              <xsl:call-template name="attribute">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeAttributes">
              <xsl:with-param name="attribRef" select="$attribRef"/>
              <xsl:with-param name="targetNS" select="$targetNS"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeComplexTypes">
    <xsl:param name="typeRef"/>
    <xsl:param name="root" select="false()"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="nodeName"/>
    <xsl:param name="targetNS"/>
 
    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:complexType[@name = $typeRef and $includeNamespace = $targetNS]">
            <xsl:for-each select="xs:complexType[@name = $typeRef and $includeNamespace = $targetNS]">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="root" select="$root"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="instance" select="$instance"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
                <xsl:with-param name="commented" select="$commented"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeComplexTypes">
              <xsl:with-param name="typeRef" select="$typeRef"/>
              <xsl:with-param name="root" select="$root"/>
              <xsl:with-param name="tree" select="$tree"/>
              <xsl:with-param name="instance" select="$instance"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
              <xsl:with-param name="targetNS" select="$targetNS"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeGroups">
    <xsl:param name="typeRef"/>
    <xsl:param name="root" select="false()"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="nodeName"/>
    <xsl:param name="targetNS"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="/@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:group[@name = $typeRef and $includeNamespace = $targetNS]">
            <xsl:for-each select="/xs:group[@name = $typeRef and $includeNamespace = $targetNS]/xs:*">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="root" select="$root"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="instance" select="$instance"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
                <xsl:with-param name="commented" select="$commented"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeGroups">
              <xsl:with-param name="typeRef" select="$typeRef"/>
              <xsl:with-param name="root" select="$root"/>
              <xsl:with-param name="tree" select="$tree"/>
              <xsl:with-param name="commented" select="$commented"/>
              <xsl:with-param name="instance" select="$instance"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
              <xsl:with-param name="targetNS" select="$targetNS"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeAttributeGroups">
    <xsl:param name="typeRef"/>
    <xsl:param name="targetNS"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:attributeGroup[@name = $typeRef and $includeNamespace = $targetNS]">
            <xsl:for-each select="xs:attributeGroup[@name = $typeRef and $includeNamespace = $targetNS]">
              <xsl:call-template name="attributeGroup">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeAttributeGroups">
              <xsl:with-param name="typeRef" select="$typeRef"/>
              <xsl:with-param name="targetNS" select="$targetNS"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="includeSimpleTypes">
    <xsl:param name="typeRef"/>
    <xsl:param name="nodeName"/>
    <xsl:param name="targetNS"/>

    <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
      <xsl:variable name="impNamespace" select="@namespace"/>
      <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
        <xsl:variable name="includeNamespace" select="@targetNamespace"/>
        <xsl:choose>
          <xsl:when test="xs:simpleType[@name = $typeRef and $includeNamespace = $targetNS]">
            <xsl:for-each select="xs:simpleType[@name = $typeRef and $includeNamespace = $targetNS]">
              <xsl:call-template name="simpleType">
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeSimpleTypes">
              <xsl:with-param name="typeRef" select="$typeRef"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
              <xsl:with-param name="targetNS" select="$targetNS"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>

  <!--
    *****************************************************************************
    sample an XML Schema element
    *****************************************************************************
  -->
  <xsl:template name="element">
    <!-- is is the root? -->
    <xsl:param name="root" select="false()"/>
    <!-- it may be the nth instance of the element -->
    <xsl:param name="instance" select="1"/>
    <!-- this will be true for mandatory elements, no matter what -->
    <xsl:param name="forceInstantiate" select="false()"/>
    <!-- hold the namespace for imported schemas -->
    <xsl:param name="includeNamespace"/>
    <!-- are we building a comment? -->
    <xsl:param name="commented" select="false()"/>
    <!-- the ancestor tree for this element (to prevent infinite recursion) -->
    <xsl:param name="tree"/>

    <xsl:choose>

      <xsl:when test="not($forceInstantiate) and $sampleOptionalElements = 'n' and @minOccurs = '0'">
        <!-- do nothing, if the element is not to appear in the sample -->
      </xsl:when>

      <!-- if the element is based on a reference -->
      <xsl:when test="@ref">

        <xsl:variable name="elementRef">
          <xsl:choose>
            <xsl:when test="contains(@ref, ':')"><xsl:value-of select="substring-after(@ref, ':')"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="@ref"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="elementRefNamespace">
          <xsl:choose>
            <xsl:when test="contains(@ref, ':')">
              <xsl:variable name="prefix" select="substring-before(@ref, ':')"/>
              <xsl:value-of select="namespace::*[name() = $prefix]"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$namespace"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- look for it in the current schema, or in its included schemas -->
        <xsl:choose>
          <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $elementRefNamespace]/xs:element[@name = $elementRef]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:element[@name = $elementRef]">
              <xsl:call-template name="element">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="root" select="$root"/>
                <xsl:with-param name="commented" select="$commented"/>
                <xsl:with-param name="tree" select="$tree"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <!-- reference not found: we'll have to look somewhere else -->
            <xsl:call-template name="includeElements">
              <xsl:with-param name="elementRef" select="$elementRef"/>
              <xsl:with-param name="commented" select="$commented"/>
              <xsl:with-param name="tree" select="$tree"/>
              <xsl:with-param name="targetNS" select="$elementRefNamespace"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:when>

      <xsl:otherwise>

        <!-- we have the element name and definition: it may be sampled -->

        <!-- create an identifier for this element to add to the tree, for verification and to pass to its descendants -->
        <xsl:variable name="nodeId">
          <xsl:choose>
            <xsl:when test="$includeNamespace and $includeNamespace != ''">
              <xsl:value-of select="concat('&#xa;', @name, '&#x9;', $includeNamespace, '&#xa;')"/>
            </xsl:when>
            <xsl:when test="string-length($namespace) &gt; 0">
              <xsl:value-of select="concat('&#xa;', @name, '&#x9;', $namespace, '&#xa;')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('&#xa;', @name, '&#x9;', '&#xa;')"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <!-- sample it only if the identifier is not already present in the element's ancestor tree -->
        <xsl:if test="not(contains($tree, $nodeId))">

          <!-- use annotations to put some information on the sample document -->
          <xsl:if test="xs:annotation/xs:documentation and $instance = 1 and not($commented) and $sampleComments = 'y'">
            <xsl:comment><xsl:value-of select="xs:annotation/xs:documentation"/></xsl:comment>
          </xsl:if>

          <!--
                this level just creates the element in the result tree
                an important thing to consider is to which namespace the element belongs
                if an included namespace, the main schema's, or no namespace at all (if it wasn't declared as a targetNamespace)
                either way, the actual contents of the element are arranged by the elementContents template
          -->
          <xsl:choose>
            <xsl:when test="$includeNamespace and $includeNamespace != ''">
              <xsl:element name="{@name}" namespace="{$includeNamespace}">
                <xsl:call-template name="elementContents">
                  <xsl:with-param name="commented" select="$commented"/>
                  <xsl:with-param name="tree" select="concat($tree, $nodeId)"/>
                  <xsl:with-param name="instance" select="$instance"/>
                </xsl:call-template>
              </xsl:element>
            </xsl:when>
            <xsl:when test="string-length($namespace) &gt; 0">
              <xsl:element name="{@name}" namespace="{$namespace}">
                <!-- special case: -->
                <xsl:if test="$root">
                  <xsl:copy-of select="/*/namespace::*[. != $namespace and . != 'http://www.w3.org/2001/XMLSchema']"/>
                </xsl:if>
                <xsl:call-template name="elementContents">
                  <xsl:with-param name="commented" select="$commented"/>
                  <xsl:with-param name="tree" select="concat($tree, $nodeId)"/>
                  <xsl:with-param name="instance" select="$instance"/>
                </xsl:call-template>
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:element name="{@name}">
                <xsl:call-template name="elementContents">
                  <xsl:with-param name="commented" select="$commented"/>
                  <xsl:with-param name="tree" select="concat($tree, $nodeId)"/>
                  <xsl:with-param name="instance" select="$instance"/>
                </xsl:call-template>
              </xsl:element>
            </xsl:otherwise>
          </xsl:choose>

        </xsl:if>
      </xsl:otherwise>

    </xsl:choose>

    <!-- check for the necessity of creating new instances of this element -->
    <xsl:choose>

      <!-- but never reinstantiate inside comments -->
      <xsl:when test="$commented">
        <!-- do nothing -->
      </xsl:when>

      <!-- reinstantiate until minOccurs is reached -->
      <xsl:when test="@minOccurs &gt; 0 and $instance &lt; @minOccurs">
        <xsl:comment> mandatory instance # <xsl:value-of select="1 + $instance"/> </xsl:comment>
        <xsl:call-template name="element">
          <xsl:with-param name="instance" select="1 + $instance"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="tree" select="$tree"/>
        </xsl:call-template>
      </xsl:when>

      <!-- reinstantiate for unbounded cardinality, and reistantiation maximum parameter is not reached -->
      <xsl:when test="(@maxOccurs = 'unbounded' or $instance &lt; @maxOccurs) and $instance &lt; $sampleUnbounded">
        <xsl:comment> optional instance # <xsl:value-of select="1 + $instance"/></xsl:comment>
        <xsl:call-template name="element">
          <xsl:with-param name="instance" select="1 + $instance"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="tree" select="$tree"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <!--
      Sample the contents of an element (either of simple, complex, or mixed nature)
  -->
  <xsl:template name="elementContents">
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="elementName" select="@name"/>

    <xsl:choose>

      <!-- fixed or default values have higher priority: if present, they are used to create the sample value -->
      <xsl:when test="@fixed or @default">
        <xsl:value-of select="@fixed | @default"/>
      </xsl:when>

      <!-- if typed -->
      <xsl:when test="@type">

        <xsl:variable name="elementType">
          <xsl:choose>
            <xsl:when test="contains(@type, ':')"><xsl:value-of select="substring-after(@type, ':')"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="elementTypeNamespace">
          <xsl:choose>
            <xsl:when test="contains(@type, ':')">
              <xsl:variable name="prefix" select="substring-before(@type, ':')"/>
              <xsl:value-of select="namespace::*[name() = $prefix]"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$namespace"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

       <xsl:choose>

         <!-- an XS builtin type? -->
         <xsl:when test="$elementTypeNamespace = 'http://www.w3.org/2001/XMLSchema'">
            <xsl:call-template name="types">
              <xsl:with-param name="xstype" select="$elementType"/>
              <xsl:with-param name="nodeName" select="$elementName"/>
            </xsl:call-template>
          </xsl:when>

          <!-- if the type is a reference to a complex type defined in the current schema, use it to build the element -->
          <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $elementTypeNamespace]/xs:complexType[@name = $elementType]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:complexType[@name = $elementType]">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="commented" select="$commented"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="instance" select="$instance"/>
                <xsl:with-param name="nodeName" select="$elementName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>

          <!-- if the type is a reference to a simple type defined in the current schema, use it to build the element -->
         <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $elementTypeNamespace]/xs:simpleType[@name = $elementType]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:simpleType[@name = $elementType]">
              <xsl:call-template name="simpleType">
                <xsl:with-param name="nodeName" select="$elementName"/>
                <xsl:with-param name="instance" select="$instance"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>

          <xsl:otherwise>
            <!-- the reference was not found in the current schema:
                  look for it somewhere else, either as complex or simple types -->
            <xsl:call-template name="includeComplexTypes">
              <xsl:with-param name="typeRef" select="$elementType"/>
              <xsl:with-param name="commented" select="$commented"/>
              <xsl:with-param name="tree" select="$tree"/>
              <xsl:with-param name="instance" select="$instance"/>
              <xsl:with-param name="nodeName" select="$elementName"/>
              <xsl:with-param name="targetNS" select="$elementTypeNamespace"/>
            </xsl:call-template>
            <xsl:call-template name="includeSimpleTypes">
              <xsl:with-param name="typeRef" select="$elementType"/>
              <xsl:with-param name="commented" select="$commented"/>
              <xsl:with-param name="nodeName" select="$elementName"/>
              <xsl:with-param name="targetNS" select="$elementTypeNamespace"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>

        <!-- the definition for the element is inline, so it's either of complex or simple type
              (only one of these will be present in the schema) -->
        <xsl:for-each select="xs:complexType">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="instance" select="$instance"/>
            <xsl:with-param name="nodeName" select="$elementName"/>
          </xsl:call-template>
        </xsl:for-each>

        <xsl:for-each select="xs:simpleType">
          <xsl:call-template name="simpleType">
            <xsl:with-param name="nodeName" select="$elementName"/>
            <xsl:with-param name="instance" select="$instance"/>
          </xsl:call-template>
          
        </xsl:for-each>

      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>

  <!--
    *****************************************************************************
    sample an XML Schema attribute
    *****************************************************************************
  -->
  <xsl:template name="attribute">
    <xsl:param name="includeNamespace"/>

    <!-- optional attributes aren't sampled unless the stylesheet is parametrized otherwise -->
    <xsl:if test="($sampleOptionalAttributes = 'y' or @use = 'required') and not(@use = 'prohibited')">

      <xsl:choose>

        <!-- if there is a reference to an attribute definition, use it -->
        <xsl:when test="@ref">

          <xsl:variable name="attribRef">
            <xsl:choose>
              <xsl:when test="contains(@ref, ':')"><xsl:value-of select="substring-after(@ref, ':')"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="@ref"/></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="attribRefNamespace">
            <xsl:choose>
              <xsl:when test="contains(@ref, ':')">
                <xsl:variable name="prefix" select="substring-before(@ref, ':')"/>
                <xsl:value-of select="namespace::*[name() = $prefix]"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$namespace"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <!-- the reference is at the current schema, or at some other included schema -->
          <xsl:choose>
            <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $attribRefNamespace]/xs:attribute[@name = $attribRef]">
              <xsl:for-each select="ancestor::xs:schema[1]/xs:attribute[@name = $attribRef]">
                <xsl:call-template name="attribute">
                  <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="includeAttributes">
                <xsl:with-param name="attribRef" select="$attribRef"/>
                <xsl:with-param name="targetNS" select="$attribRefNamespace"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <!-- treat xml:* attributes as a special case: create the attribute with default values -->
        <xsl:when test="$includeNamespace = 'http://www.w3.org/XML/1998/namespace'">
          <xsl:attribute name="{concat('xml:', @name)}">
            <xsl:choose>
              <xsl:when test="@name = 'space'">
                <xsl:value-of select="$sampleDefaultXMLSpace"/>
              </xsl:when>
              <xsl:when test="@name = 'lang'">
                <xsl:value-of select="$sampleDefaultXMLLang"/>
              </xsl:when>
              <xsl:when test="@name = 'base'">
                <xsl:value-of select="$sampleDefaultXMLBase"/>
              </xsl:when>
            </xsl:choose>
          </xsl:attribute>
        </xsl:when>

        <!-- when the attribute is namespaced, check for the necessity to qualify its name -->
        <xsl:when test="$includeNamespace">

          <!-- get the prefix for the namespace, as declared in the main schema -->
          <xsl:variable name="prefix">
            <xsl:call-template name="getPrefix">
              <xsl:with-param name="namespace" select="$includeNamespace"/>
            </xsl:call-template>
          </xsl:variable>

          <!-- if the prefix is declared, it can be safely prepended to the attribute name -->
          <xsl:choose>
            <xsl:when test="$prefix != ''">
              <xsl:attribute name="{concat($prefix, ':', @name)}">
                <xsl:call-template name="attributeContents"/>
              </xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
              <!-- if not, then just link to the attribute (an autogenerated prefix will be provided by the DOM) -->
              <xsl:attribute name="{@name}" namespace="{$includeNamespace}">
                <xsl:call-template name="attributeContents"/>
              </xsl:attribute>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>

        <xsl:otherwise>
          <!-- no namespaced attributes: just create it -->
          <xsl:attribute name="{@name}">
            <xsl:call-template name="attributeContents"/>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!--
      Sample the contents of an attribute
  -->
  <xsl:template name="attributeContents">

    <xsl:variable name="attributeName" select="@name"/>

    <xsl:choose>

      <!-- fixed or default values have higher priority: if present, they will be used as the attribute's value -->
      <xsl:when test="@fixed or @default">
        <xsl:value-of select="@fixed | @default"/>
      </xsl:when>

      <!-- if typed -->
      <xsl:when test="@type">

        <xsl:variable name="elementType">
          <xsl:choose>
            <xsl:when test="contains(@type, ':')"><xsl:value-of select="substring-after(@type, ':')"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="@type"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="elementTypeNamespace">
          <xsl:choose>
            <xsl:when test="contains(@type, ':')">
              <xsl:variable name="prefix" select="substring-before(@type, ':')"/>
              <xsl:value-of select="namespace::*[name() = $prefix]"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$namespace"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:choose>

          <!-- make a new attempt: is it a XSD type? -->
          <xsl:when test="$elementTypeNamespace = 'http://www.w3.org/2001/XMLSchema'">
            <xsl:call-template name="types">
              <xsl:with-param name="xstype" select="$elementType"/>
              <xsl:with-param name="nodeName" select="$attributeName"/>
            </xsl:call-template>
          </xsl:when>

          <!-- look for the type definition at the current schema -->
          <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $elementTypeNamespace]/xs:simpleType[@name = $elementType]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:simpleType[@name = $elementType]">
              <xsl:call-template name="simpleType">
                <xsl:with-param name="nodeName" select="$attributeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <!-- or at somewhere else -->
            <xsl:call-template name="includeSimpleTypes">
              <xsl:with-param name="typeRef" select="$elementType"/>
              <xsl:with-param name="nodeName" select="$attributeName"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:when>

      <!-- type is inline? create the value based in the definition -->
      <xsl:when test="xs:simpleType">
        <xsl:for-each select="xs:simpleType">
          <xsl:call-template name="simpleType">
            <xsl:with-param name="nodeName" select="$attributeName"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

    </xsl:choose>

    <!-- for all other cases, the attribute value will be left blank -->

  </xsl:template>

  <!--
      Sample a group of attributes under an attributeGroup XML Schema element
  -->
  <xsl:template name="attributeGroup">
    <xsl:param name="includeNamespace"/>
    <xsl:param name="groupRef"/>

    <xsl:choose>

      <!-- if the definition of the group is inline, check for attribute groups and attributes under it -->
      <xsl:when test="not($groupRef)">
        <xsl:for-each select="xs:attributeGroup">
          <xsl:call-template name="attributeGroup">
            <xsl:with-param name="groupRef" select="@ref"/>
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="xs:attribute">
          <xsl:call-template name="attribute">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <xsl:otherwise>

        <xsl:variable name="groupType">
          <xsl:choose>
            <xsl:when test="contains($groupRef, ':')"><xsl:value-of select="substring-after($groupRef, ':')"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$groupRef"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="groupTypeNamespace">
          <xsl:choose>
            <xsl:when test="contains($groupRef, ':')">
              <xsl:variable name="prefix" select="substring-before($groupRef, ':')"/>
              <xsl:value-of select="namespace::*[name() = $prefix]"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$namespace"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:choose>

          <!-- if there is a reference to the group, look for it in the current schema -->
          <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $groupTypeNamespace]/xs:attributeGroup[@name = $groupType]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:attributeGroup[@name = $groupType]">
              <xsl:call-template name="attributeGroup">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>

          <xsl:otherwise>
            <!-- reference not found? look for it somewhere else -->
            <xsl:call-template name="includeAttributeGroups">
              <xsl:with-param name="typeRef" select="$groupRef"/>
              <xsl:with-param name="targetNS" select="$groupTypeNamespace"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!--
      Sample a complex typed element, under an XML Schema complexType element, or one of its descendants

      This template is called to process a complexType, or to process one direct descendant of complexType.
      The actual sample generator is the template complexTypeComposition, that this calls
  -->
  <xsl:template name="complexType">
    <!-- same parameters as in the "element" sampler -->
    <xsl:param name="includeNamespace"/>
    <xsl:param name="root" select="false()"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="nodeName"/>

    <!-- deal with attributes, frontmost, either as groups or single -->
    <xsl:for-each select="xs:attributeGroup">
      <xsl:call-template name="attributeGroup">
        <xsl:with-param name="groupRef" select="@ref"/>
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:for-each select="xs:attribute">
      <xsl:call-template name="attribute">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:choose>

      <!-- for extensions and restrictions, ignore -->
      <xsl:when test="local-name() = 'extension' or local-name() = 'restriction'">
        <!-- do nothing, just deal with attributes, the extended items will come back later on -->
      </xsl:when>

      <!-- if (other) complexType descendant, process its composition -->
      <xsl:when test="local-name() != 'complexType'">
        <xsl:call-template name="complexTypeComposition">
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="instance" select="$instance"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>

        <!-- it's a complexType: process the composition of all of its descendants, except for attributes -->
        <xsl:for-each select="xs:*[not(starts-with(local-name(), 'attribute'))]">
          <xsl:call-template name="complexTypeComposition">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="instance" select="$instance"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <!--
      Controller for a complex type composition: directs the processing to adequate templates
  -->
  <xsl:template name="complexTypeComposition">
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="tree"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="nodeName"/>

    <xsl:choose>

      <!-- for sequences, iterate through all of its components -->
      <xsl:when test="local-name() = 'sequence'">
        <xsl:call-template name="iteratorComplexTypes">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="last" select="number($sampleUnbounded)"/>
        </xsl:call-template>
      </xsl:when>

      <!-- for all, forcibly instantiate all of its elements -->
      <xsl:when test="local-name() = 'all'">
        <xsl:for-each select="xs:element">
          <xsl:call-template name="element">
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="forceInstantiate" select="true()"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>

      <!-- for choice, just one of its elements (but it may be repeated) -->
      <xsl:when test="local-name() = 'choice'">
        <xsl:call-template name="iteratorChoices">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="current" select="$instance"/>
          <xsl:with-param name="last" select="number($sampleUnbounded)"/>
        </xsl:call-template>
      </xsl:when>

      <!-- for groups, iterate through all of its components (one of the previous structures) -->
      <xsl:when test="local-name() = 'group'">
        <xsl:call-template name="iteratorGroups">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="last" select="number($sampleUnbounded)"/>
        </xsl:call-template>
      </xsl:when>

      <!-- a simpleContent (text only) -->
      <xsl:when test="local-name() = 'simpleContent'">
        <xsl:call-template name="complexTypeSimpleContent">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
        </xsl:call-template>
      </xsl:when>

      <!-- a complexContent (text and elements) -->
      <xsl:when test="local-name() = 'complexContent'">
        <xsl:call-template name="complexTypeComplexContent">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="last" select="number($sampleUnbounded)"/>
        </xsl:call-template>
      </xsl:when>

      <!-- an element (as descendant of other complexType structures) -->
      <xsl:when test="local-name() = 'element'">
        <xsl:call-template name="element">
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="instance" select="$instance"/>
        </xsl:call-template>
      </xsl:when>

    </xsl:choose>

  </xsl:template>

  <!-- sample an XML Schema choice element -->
  <xsl:template name="complexTypeChoice">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="instance" select="1"/>

    <!--
          for choices, there are 3 possible strategies:
            sequence - the nth instance samples the nth element (the first samples the first, the second samples the second...)
            first - samples the first element
            comment - samples the first, comment the rest
      -->
    <xsl:choose>
      <!-- strategy: sequence -->
      <xsl:when test="$sampleChoiceStrategy = 'sequence'">
        <xsl:for-each select="xs:*[position() = $instance or ($instance &gt; last() and position() = 1)]">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="instance" select="$instance"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <!-- strategies: first and comment -->
        <xsl:for-each select="xs:*[1]">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:for-each>
        <!-- strategy: comment (the first was just sampled) -->
        <xsl:if test="$sampleChoiceStrategy = 'comment'">
          <xsl:variable name="subtree">
            <xsl:for-each select="xs:*[position() &gt; 1]">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="commented" select="true()"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:variable>
          <!-- start comment, if it was not already in course -->
          <xsl:if test="not($commented)"><xsl:text disable-output-escaping="yes">&lt;!-- </xsl:text></xsl:if>
          <xsl:copy-of select="$subtree"/>
          <!-- end comment, if it was not already in course -->
          <xsl:if test="not($commented)"><xsl:text disable-output-escaping="yes">--&gt;</xsl:text></xsl:if>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- sample an XML Schema simpleContent element -->
  <xsl:template name="complexTypeSimpleContent">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>

    <!-- process attributes -->
    <xsl:for-each select="xs:extension | xs:restriction">
      <xsl:call-template name="complexType">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:for-each>

    <!-- hold a reference to the content, and to its identifier or type -->
    <xsl:variable name="definition" select="xs:extension | xs:restriction"/>

    <xsl:variable name="typeRef">
      <xsl:choose>
        <xsl:when test="contains($definition/@base, ':')"><xsl:value-of select="substring-after($definition/@base, ':')"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$definition/@base"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="typeRefNamespace">
      <xsl:choose>
        <xsl:when test="contains($definition/@base, ':')">
          <xsl:variable name="prefix" select="substring-before($definition/@base, ':')"/>
          <xsl:value-of select="namespace::*[name() = $prefix]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$namespace"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- try to produce a sample, if the simple types can be found or derived -->
    <xsl:choose>

      <!-- for direct extensions, sample the value -->
      <xsl:when test="xs:extension and $typeRefNamespace = 'http://www.w3.org/2001/XMLSchema'">
        <xsl:call-template name="types">
          <xsl:with-param name="xstype" select="$typeRef"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <!-- for direct restrictions, sample the restricted value -->
      <xsl:when test="xs:restriction and $typeRefNamespace = 'http://www.w3.org/2001/XMLSchema'">
        <xsl:call-template name="restrictedTypes">
          <xsl:with-param name="xstype" select="$typeRef"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <!-- the reference to the extension must be located either at the current schema, or at an included one -->
      <xsl:when test="xs:extension">
        <xsl:choose>
          <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $typeRefNamespace]/xs:complexType[@name = $typeRef]">
            <xsl:for-each select="ancestor::xs:schema[1]/xs:complexType[@name = $typeRef]">
              <xsl:call-template name="complexType">
                <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                <xsl:with-param name="commented" select="$commented"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="includeSimpleTypes">
              <xsl:with-param name="typeRef" select="$typeRef"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
              <xsl:with-param name="targetNS" select="$typeRefNamespace"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- for a restriction, locate the reference to XML Schema types and, if found, apply the restriction to sample a value -->
      <xsl:when test="xs:restriction">
        <xsl:variable name="rtype">
          <xsl:call-template name="getXSType">
            <xsl:with-param name="dbase" select="$typeRef"/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$rtype != ''">
          <xsl:call-template name="restrictedTypes">
            <xsl:with-param name="xstype" select="$rtype"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>

    </xsl:choose>

    <!-- go deeper in the definition, by sampling whatever has yet to be sampled -->
    <xsl:for-each select="$definition/xs:*[not(starts-with(local-name(), 'attribute'))]">
      <xsl:call-template name="complexType">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>                
      </xsl:call-template>
    </xsl:for-each>

  </xsl:template>

  <!-- sample an XML Schema complexContent element -->
  <xsl:template name="complexTypeComplexContent">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="instance" select="1"/>

    <xsl:for-each select="xs:extension | xs:restriction">
      <xsl:call-template name="complexType">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:variable name="definition" select="xs:extension | xs:restriction"/>

    <xsl:variable name="typeRef">
      <xsl:choose>
        <xsl:when test="contains($definition/@base, ':')"><xsl:value-of select="substring-after($definition/@base, ':')"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$definition/@base"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="typeRefNamespace">
      <xsl:choose>
        <xsl:when test="contains($definition/@base, ':')">
          <xsl:variable name="prefix" select="substring-before($definition/@base, ':')"/>
          <xsl:value-of select="namespace::*[name() = $prefix]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$namespace"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>

      <xsl:when test="xs:extension and $typeRefNamespace = 'http://www.w3.org/2001/XMLSchema'">
        <xsl:call-template name="types">
          <xsl:with-param name="xstype" select="$typeRef"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="xs:restriction and $typeRefNamespace = 'http://www.w3.org/2001/XMLSchema'">
        <xsl:call-template name="restrictedTypes">
          <xsl:with-param name="xstype" select="$typeRef"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>

        <xsl:if test="xs:extension">

          <xsl:choose>
            <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $typeRefNamespace]/xs:complexType[@name = $typeRef]">
              <xsl:for-each select="ancestor::xs:schema[1]/xs:complexType[@name = $typeRef]">
                <xsl:call-template name="complexType">
                  <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
                  <xsl:with-param name="commented" select="$commented"/>
                  <xsl:with-param name="tree" select="$tree"/>
                  <xsl:with-param name="nodeName" select="$nodeName"/>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="includeComplexTypes">
                <xsl:with-param name="typeRef" select="$typeRef"/>
                <xsl:with-param name="commented" select="$commented"/>
                <xsl:with-param name="tree" select="$tree"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>

        <xsl:for-each select="$definition/xs:*">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>                
          </xsl:call-template>
        </xsl:for-each>

      </xsl:otherwise>

    </xsl:choose>

    <xsl:if test="@mixed = 'true'">
      <xsl:value-of select="$sampleDefaultTextData"/>
    </xsl:if>

  </xsl:template>

  <xsl:template name="getXSType">
    <xsl:param name="dbase" select="@base"/>

    <xsl:variable name="xsType">
      <xsl:choose>
        <xsl:when test="contains($dbase, ':')"><xsl:value-of select="substring-after($dbase, ':')"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$dbase"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="xsTypeNamespace">
      <xsl:choose>
        <xsl:when test="contains($dbase, ':')">
          <xsl:variable name="prefix" select="substring-before($dbase, ':')"/>
          <xsl:value-of select="namespace::*[name() = $prefix]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$namespace"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$xsTypeNamespace = 'http://www.w3.org/2001/XMLSchema'">
        <xsl:value-of select="$xsType"/>
      </xsl:when>

      <xsl:when test="ancestor::xs:schema[1]/xs:complexType[@name = $dbase]/xs:simpleContent/xs:extension">
        <xsl:call-template name="getXSType">
          <xsl:with-param name="dbase" select="ancestor::xs:schema[1]/xs:complexType[@name = $dbase]/xs:simpleContent/xs:extension/@base"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="ancestor::xs:schema[1]/xs:complexType[@name = $dbase]/xs:simpleContent/xs:restriction">
        <xsl:call-template name="getXSType">
          <xsl:with-param name="dbase" select="ancestor::xs:schema[1]/xs:complexType[@name = $dbase]/xs:simpleContent/xs:restriction/@base"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:for-each select="ancestor::xs:schema[1]/xs:include | ancestor::xs:schema[1]/xs:import">
          <xsl:variable name="impNamespace" select="@namespace"/>
          <xsl:for-each select="(document(@schemaLocation)//xs:schema | //xs:schema[@targetNamespace = $impNamespace])[1]">
            <xsl:call-template name="getXSType">
              <xsl:with-param name="dbase" select="$dbase"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="unionMembers">
    <xsl:param name="soFar" select="1"/>
    <xsl:param name="nodeName"/>

    <xsl:call-template name="unionMembersInList">
      <xsl:with-param name="soFar" select="$soFar"/>
      <xsl:with-param name="nodeName" select="$nodeName"/>
    </xsl:call-template>

  </xsl:template>

  <xsl:template name="unionMembersInList">
    <xsl:param name="tokenList" select="xs:union/@memberTypes"/> 
    <xsl:param name="soFar" select="1"/>
    <xsl:param name="nodeName"/>

    <xsl:variable name="normList" select="concat(normalize-space($tokenList), ' ')"/>
    <xsl:variable name="thisToken" select="substring-before($normList, ' ')"/>
    <xsl:variable name="nextTokens" select="substring-after($normList, ' ')"/>

    <xsl:variable name="typeRef">
      <xsl:choose>
        <xsl:when test="contains($thisToken, ':')"><xsl:value-of select="substring-after($thisToken, ':')"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$thisToken"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="typeRefNamespace">
      <xsl:choose>
        <xsl:when test="contains($thisToken, ':')">
          <xsl:variable name="prefix" select="substring-before($thisToken, ':')"/>
          <xsl:value-of select="namespace::*[name() = $prefix]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$namespace"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:choose>

      <!-- reached the end, check now the children -->
      <xsl:when test="$thisToken = ''">
        <xsl:call-template name="unionChildren">
          <xsl:with-param name="soFar" select="$soFar"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <!-- for builtin types, decrement the count, if not at the targeted member -->
      <xsl:when test="$typeRefNamespace = 'http://www.w3.org/2001/XMLSchema'">
        <xsl:choose>
          <xsl:when test="$soFar &lt;= 1">
            <xsl:call-template name="types">
              <xsl:with-param name="xstype" select="$typeRef"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="unionMembersInList">
              <xsl:with-param name="soFar" select="number($soFar) - 1"/>
              <xsl:with-param name="tokenList" select="$nextTokens"/>
              <xsl:with-param name="nodeName" select="$nodeName"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- otherwise, start by locating the type -->
      <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $typeRefNamespace]/xs:simpleType[@name = $typeRef]">
        <xsl:for-each select="ancestor::xs:schema[1]/xs:simpleType[@name = $typeRef]">
          <xsl:choose>
            <xsl:when test="$soFar &lt;= 1">
              <xsl:call-template name="simpleType">
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="unionMembersInList">
                <xsl:with-param name="soFar" select="number($soFar) - 1"/>
                <xsl:with-param name="tokenList" select="$nextTokens"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>

      </xsl:when>

      <xsl:otherwise>
        <xsl:call-template name="simpleType">
          <xsl:with-param name="instance" select="number($soFar) - 1"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="unionCycle" select="true()"/>
        </xsl:call-template>
      </xsl:otherwise>

    </xsl:choose>

  </xsl:template>

  <xsl:template name="unionChildren">
    <xsl:param name="positionMark" select="1"/> 
    <xsl:param name="soFar" select="1"/>
    <xsl:param name="nodeName"/>
    
    <xsl:choose>
      
      <xsl:when test="$positionMark &lt;= count(xs:union/xs:simpleType)">

        <xsl:for-each select="xs:union/xs:simpleType[position() = $positionMark]">
          
          <xsl:choose>
            <xsl:when test="$soFar &lt;= 1">
              <xsl:call-template name="simpleType">
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="unionChildren">
                <xsl:with-param name="positionMark" select="$positionMark + 1"/>
                <xsl:with-param name="soFar" select="number($soFar) - 1"/>
                <xsl:with-param name="nodeName" select="$nodeName"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      
      <xsl:otherwise>
        <xsl:if test="$soFar &gt;= 1">
          <xsl:call-template name="simpleType">
            <xsl:with-param name="instance" select="$soFar"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
            <xsl:with-param name="unionCycle" select="true()"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>

  <!--
    iterator* templates

    repeate the sampling of nodes, based on some specified limit (from 1 to last)
  -->
  <xsl:template name="iteratorGroups">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="current" select="1"/>
    <xsl:param name="last" select="1"/>

    <xsl:variable name="gref">
      <xsl:choose>
        <xsl:when test="contains(@ref, ':')"><xsl:value-of select="substring-after(@ref, ':')"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="@ref"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="grefNamespace">
      <xsl:choose>
        <xsl:when test="contains(@ref, ':')">
          <xsl:variable name="prefix" select="substring-before(@ref, ':')"/>
          <xsl:value-of select="namespace::*[name() = $prefix]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$namespace"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="ancestor::xs:schema[position() = 1 and string(@targetNamespace) = $grefNamespace]/xs:group[@name = $gref]">
        <xsl:for-each select="ancestor::xs:schema[1]/xs:group[@name = $gref]/xs:*">
          <xsl:call-template name="complexType">
            <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
            <xsl:with-param name="commented" select="$commented"/>
            <xsl:with-param name="tree" select="$tree"/>
            <xsl:with-param name="instance" select="$current"/>
            <xsl:with-param name="nodeName" select="$nodeName"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="includeGroups">
          <xsl:with-param name="typeRef" select="$gref"/>
          <xsl:with-param name="commented" select="$commented"/>
          <xsl:with-param name="tree" select="$tree"/>
          <xsl:with-param name="instance" select="$current"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="targetNS" select="$grefNamespace"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$current &lt; $last and (@maxOccurs = 'unbounded' or $current &lt; @maxOccurs)">
      <xsl:call-template name="iteratorGroups">
        <xsl:with-param name="last" select="$last"/>
        <xsl:with-param name="current" select="$current + 1"/>
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="iteratorComplexTypes">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="current" select="1"/>
    <xsl:param name="last" select="1"/>

    <xsl:for-each select="xs:*">
      <xsl:call-template name="complexType">
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="instance" select="$current"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:if test="$current &lt; $last and (@maxOccurs = 'unbounded' or $current &lt; @maxOccurs)">
      <xsl:call-template name="iteratorComplexTypes">
        <xsl:with-param name="last" select="$last"/>
        <xsl:with-param name="current" select="$current + 1"/>
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="iteratorChoices">
    <xsl:param name="nodeName"/>
    <xsl:param name="tree"/>
    <xsl:param name="includeNamespace"/>
    <xsl:param name="commented" select="false()"/>
    <xsl:param name="current" select="1"/>
    <xsl:param name="last" select="1"/>

    <xsl:call-template name="complexTypeChoice">
      <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
      <xsl:with-param name="commented" select="$commented"/>
      <xsl:with-param name="tree" select="$tree"/>
      <xsl:with-param name="instance" select="$current"/>
      <xsl:with-param name="nodeName" select="$nodeName"/>
    </xsl:call-template>

    <xsl:if test="$current &lt; $last and (@maxOccurs = 'unbounded' or $current &lt; @maxOccurs)">
      <xsl:call-template name="iteratorChoices">
        <xsl:with-param name="last" select="$last"/>
        <xsl:with-param name="current" select="$current + 1"/>
        <xsl:with-param name="includeNamespace" select="$includeNamespace"/>
        <xsl:with-param name="commented" select="$commented"/>
        <xsl:with-param name="tree" select="$tree"/>
        <xsl:with-param name="nodeName" select="$nodeName"/>
      </xsl:call-template>
    </xsl:if>

  </xsl:template>

  <!-- samples a simpleType definition -->
  <xsl:template name="simpleType">
    <xsl:param name="nodeName" select="@name"/>
    <xsl:param name="instance" select="1"/>
    <xsl:param name="unionCycle" select="false()"/>

    <xsl:choose>

      <xsl:when test="xs:restriction and (not($unionCycle) or $instance &lt;= 1)">
        <xsl:call-template name="restrictedTypes">
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="xs:restriction">
        <xsl:call-template name="simpleType">
          <xsl:with-param name="unionCycle" select="$unionCycle"/>
          <xsl:with-param name="instance" select="number($instance) - 1"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="xs:union">
        <xsl:call-template name="unionMembers">
          <xsl:with-param name="nodeName" select="$nodeName"/>
          <xsl:with-param name="soFar" select="$instance"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <!-- get the actual element/attribute contents, based on its XS type -->
  <xsl:template name="types">
    <xsl:param name="xstype" select="@type"/>
    <xsl:param name="nodeName" select="@name"/>

    <xsl:choose>
      <xsl:when test="contains($xsGroupString, $xstype)">
        <xsl:call-template name="string">
          <xsl:with-param name="base" select="$xstype"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupNumeric, $xstype)">
        <xsl:call-template name="number">
          <xsl:with-param name="base" select="$xstype"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupDate, $xstype)">
        <xsl:call-template name="date">
          <xsl:with-param name="base" select="$xstype"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupBinary, $xstype)">
        <xsl:call-template name="binary">
          <xsl:with-param name="base" select="$xstype"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$xstype = $xsBoolean">
        <xsl:call-template name="boolean"/>
      </xsl:when>
      <xsl:when test="$xstype = $xsAnyURI">
        <xsl:call-template name="URI"/>
      </xsl:when>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="URI">
    <xsl:choose>
      <xsl:when test="$sampleURIasHTTP = 'y'">
        <xsl:value-of select="$sampleDefaultHTTP"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultURI"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="boolean">
    <xsl:choose>
      <xsl:when test="$sampleBooleanAsNumber = 'y'">1</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultBoolean"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="binary">
    <xsl:param name="base"/>
    <xsl:choose>
      <xsl:when test="$base = $xsBase64Binary">
        <xsl:value-of select="$sampleDefaultBase64Binary"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultHexBinary"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="date">
    <xsl:param name="base"/>
    <xsl:choose>
      <xsl:when test="$base = $xsDateTime">
        <xsl:value-of select="$sampleDefaultDate"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring($sampleDefaultDate, 1, 10)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="number">
    <xsl:param name="base"/>
    <xsl:choose>
      <xsl:when test="$base = $xsNegativeInteger">-1</xsl:when>
      <xsl:when test="$base = $xsPositiveInteger">1</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultNumber"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="string">
    <xsl:param name="base"/>
    <xsl:param name="nodeName"/>

    <xsl:choose>
      <xsl:when test="$base = $xsID">
        <xsl:value-of select="generate-id()"/>
      </xsl:when>
      <xsl:when test="$base = $xsLanguage">
        <xsl:value-of select="$sampleDefaultXMLLang"/>
      </xsl:when>
      <xsl:when test="$sampleStringSource = 'name'">
        <xsl:value-of select="$nodeName"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$sampleDefaultString"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- get the actual element/attribute contents, based on its type and some restrition that applies -->
  <xsl:template name="restrictedTypes">
    <xsl:param name="nodeName" select="@name"/>
    <xsl:param name="xstype" select="xs:restriction/@base"/>

    <xsl:variable name="definition" select="xs:restriction"/>
    <xsl:variable name="base">
      <xsl:choose>
        <xsl:when test="contains($xstype, ':')"><xsl:value-of select="substring-after($xstype, ':')"/></xsl:when>
        <xsl:otherwise><xsl:value-of select="$xstype"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="contains($xsGroupString, $base)">
        <xsl:call-template name="restrictedString">
          <xsl:with-param name="definition" select="$definition"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupNumeric, $base)">
        <xsl:call-template name="restrictedNumber">
          <xsl:with-param name="definition" select="$definition"/>
          <xsl:with-param name="base" select="$base"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($xsGroupDate, $base)">
        <xsl:call-template name="restrictedDate">
          <xsl:with-param name="definition" select="$definition"/>
          <xsl:with-param name="base" select="$base"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="@type = $xsBoolean">
        <xsl:call-template name="boolean"/>
      </xsl:when>
      <xsl:when test="@type = $xsAnyURI">
        <xsl:call-template name="URI"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="restrictedString">
          <xsl:with-param name="definition" select="$definition"/>
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="restrictedDate">
    <xsl:param name="definition"/>
    <xsl:param name="base"/>

    <xsl:choose>
      <xsl:when test="$definition/xs:pattern and $samplePattern = 'y'">
        <xsl:value-of select="$definition/xs:pattern/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:enumeration">
        <xsl:value-of select="$definition/xs:enumeration[1]/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:minInclusive">
        <xsl:value-of select="$definition/xs:minInclusive/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:maxInclusive">
        <xsl:value-of select="$definition/xs:maxInclusive/@value"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="date">
          <xsl:with-param name="base" select="$base"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="restrictedNumber">
    <xsl:param name="definition"/>
    <xsl:param name="base"/>

    <xsl:variable name="numericValue">
      <xsl:choose>
        <xsl:when test="($definition/xs:minInclusive | $definition/xs:minExclusive) and ($definition/xs:maxInclusive | $definition/xs:maxExclusive)">
          <xsl:value-of
            select="($definition/xs:minInclusive/@value | $definition/xs:minExclusive/@value) + floor((($definition/xs:maxInclusive/@value | $definition/xs:maxExclusive/@value) - ($definition/xs:minInclusive/@value | $definition/xs:minExclusive/@value)) div 2)"
          />
        </xsl:when>
        <xsl:when test="$definition/xs:minInclusive">
          <xsl:value-of select="$definition/xs:minInclusive/@value"/>
        </xsl:when>
        <xsl:when test="$definition/xs:maxInclusive">
          <xsl:value-of select="$definition/xs:maxInclusive/@value"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="number">
            <xsl:with-param name="base" select="$base"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$definition/xs:pattern and $samplePattern = 'y'">
        <xsl:value-of select="$definition/xs:pattern/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:enumeration">
        <xsl:value-of select="$definition/xs:enumeration[1]/@value"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="floor($numericValue)"/>
        <xsl:if test="$base = $xsDecimal and (not($definition/xs:fractionDigits) or $definition/xs:fractionDigits/@value &gt; 0)">.</xsl:if>
        <xsl:choose>
          <xsl:when test="$definition/xs:fractionDigits">
            <xsl:value-of select="substring('000000000000000000', 1, $definition/xs:fractionDigits/@value)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="$base = $xsDecimal">
              <xsl:text>00</xsl:text>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

  <xsl:template name="restrictedString">
    <xsl:param name="definition"/>
    <xsl:param name="base"/>
    <xsl:param name="nodeName"/>

    <xsl:choose>
      <xsl:when test="$base = $xsID">
        <xsl:value-of select="generate-id()"/>
      </xsl:when>
      <xsl:when test="$definition/xs:enumeration">
        <xsl:value-of select="$definition/xs:enumeration[1]/@value"/>
      </xsl:when>
      <xsl:when test="$definition/xs:pattern and $samplePattern = 'y'">
        <xsl:value-of select="$definition/xs:pattern/@value"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="string">
          <xsl:with-param name="base" select="$base"/>
          <xsl:with-param name="nodeName" select="$nodeName"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:if test="$sampleStringLength = 'y' and $definition and ($definition/xs:minLength or $definition/xs:maxLength)">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="$definition/xs:minLength/@value"/>
      <xsl:text>..</xsl:text>
      <xsl:value-of select="$definition/xs:maxLength/@value"/>
      <xsl:text>]</xsl:text>
    </xsl:if>

  </xsl:template>

</xsl:stylesheet>