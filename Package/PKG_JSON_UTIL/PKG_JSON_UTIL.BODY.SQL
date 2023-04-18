
CREATE OR REPLACE PACKAGE BODY PKG_JSON_UTIL
AS

  /*

  PURPOSE:    JSON UTILITIES FOR PL/SQL

  REMARKS:

  WHO     DATE        DESCRIPTION
  ------  ----------  -------------------------------------
  VALK    10.01.2018  CREATED - WINTHOR
  SAN
  DRO

  */


  G_JSON_NULL_OBJECT             CONSTANT VARCHAR2(20) := '{ }';


FUNCTION GET_XML_TO_JSON_STYLESHEET RETURN VARCHAR2
AS
BEGIN

  /*

  Purpose:    return XSLT stylesheet for XML to JSON transformation



  Who     Date        Description
  ------  ----------  -------------------------------------
  VALK    10.01.2018  Created - Winthor
  SAN
  DRO

  */


  return '<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--
  Copyright (c) 2006, Doeke Zanstra
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification,
  are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer. Redistributions in binary
  form must reproduce the above copyright notice, this list of conditions and the
  following disclaimer in the documentation and/or other materials provided with
  the distribution.

  Neither the name of the dzLib nor the names of its contributors may be used to
  endorse or promote products derived from this software without specific prior
  written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
  THE POSSIBILITY OF SUCH DAMAGE.
-->

  <xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="UTF-8" media-type="text/x-json"/>
  <xsl:strip-space elements="*"/>
  <!--contant-->
  <xsl:variable name="d">0123456789</xsl:variable>

  <!-- ignore document text -->
  <xsl:template match="text()[preceding-sibling::node() or following-sibling::node()]"/>

  <!-- string -->
  <xsl:template match="text()">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="."/>
    </xsl:call-template>
  </xsl:template>

  <!-- Main template for escaping strings; used by above template and for object-properties
       Responsibilities: placed quotes around string, and chain up to next filter, escape-bs-string -->
  <xsl:template name="escape-string">
    <xsl:param name="s"/>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="escape-bs-string">
      <xsl:with-param name="s" select="$s"/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>

  <!-- Escape the backslash (\) before everything else. -->
  <xsl:template name="escape-bs-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,''\'')">
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''\''),''\\'')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-bs-string">
          <xsl:with-param name="s" select="substring-after($s,''\'')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Escape the double quote ("). -->
  <xsl:template name="escape-quot-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,''&quot;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&quot;''),''\&quot;'')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="substring-after($s,''&quot;'')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Replace tab, line feed and/or carriage return by its matching escape code. Can''t escape backslash
       or double quote here, because they don''t replace characters (&#x0; becomes \t), but they prefix
       characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be
       processed first. This function can''t do that. -->
  <xsl:template name="encode-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <!-- tab -->
      <xsl:when test="contains($s,''&#x9;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#x9;''),''\t'',substring-after($s,''&#x9;''))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- line feed -->
      <xsl:when test="contains($s,''&#xA;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#xA;''),''\n'',substring-after($s,''&#xA;''))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- carriage return -->
      <xsl:when test="contains($s,''&#xD;'')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,''&#xD;''),''\r'',substring-after($s,''&#xD;''))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$s"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- number (no support for javascript mantise) -->
  <xsl:template match="text()[not(string(number())=''NaN'')]">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- boolean, case-insensitive -->
  <xsl:template match="text()[translate(.,''TRUE'',''true'')=''true'']">true</xsl:template>
  <xsl:template match="text()[translate(.,''FALSE'',''false'')=''false'']">false</xsl:template>

  <!-- item:null -->
  <xsl:template match="*[count(child::node())=0]">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="local-name()"/>
    </xsl:call-template>
    <xsl:text>:null</xsl:text>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">}</xsl:if> <!-- MBR 30.01.2010: added this line as it appeared to be missing from stylesheet -->
  </xsl:template>

  <!-- object -->
  <xsl:template match="*" name="base">
    <xsl:if test="not(preceding-sibling::*)">{</xsl:if>
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="name()"/>
    </xsl:call-template>
    <xsl:text>:</xsl:text>
    <xsl:apply-templates select="child::node()"/>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">}</xsl:if>
  </xsl:template>

  <!-- array -->
  <xsl:template match="*[count(../*[name(../*)=name(.)])=count(../*) and count(../*)&gt;1]">
    <xsl:if test="not(preceding-sibling::*)">[</xsl:if>
    <xsl:choose>
      <xsl:when test="not(child::node())">
        <xsl:text>null</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="child::node()"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">]</xsl:if>
  </xsl:template>

  <!-- convert root element to an anonymous container -->
  <xsl:template match="/">
    <xsl:apply-templates select="node()"/>
  </xsl:template>

</xsl:stylesheet>';

END GET_XML_TO_JSON_STYLESHEET;


FUNCTION REF_CURSOR_TO_JSON (P_REF_CURSOR IN SYS_REFCURSOR,
                             P_MAX_ROWS IN NUMBER := NULL,
                             P_SKIP_ROWS IN NUMBER := NULL) RETURN CLOB
AS
  L_CTX         DBMS_XMLGEN.CTXHANDLE;
  L_NUM_ROWS    PLS_INTEGER;
  L_XML         XMLTYPE;
  L_JSON        XMLTYPE;
  L_RETURNVALUE CLOB;
BEGIN


  /*

  PURPOSE:    GENERATE JSON FROM REF CURSOR

  REMARKS:

  WHO     DATE        DESCRIPTION
  ------  ----------  -------------------------------------
  VALK    10.01.2018  CREATED - WINTHOR
  SAN
  DRO

  */

  L_CTX := DBMS_XMLGEN.NEWCONTEXT (P_REF_CURSOR);

  DBMS_XMLGEN.SETNULLHANDLING (L_CTX, DBMS_XMLGEN.EMPTY_TAG);

  -- FOR PAGINATION

  IF P_MAX_ROWS IS NOT NULL THEN
    DBMS_XMLGEN.SETMAXROWS (L_CTX, P_MAX_ROWS);
  END IF;

  IF P_SKIP_ROWS IS NOT NULL THEN
    DBMS_XMLGEN.SETSKIPROWS (L_CTX, P_SKIP_ROWS);
  END IF;

  -- GET THE XML CONTENT
  L_XML := DBMS_XMLGEN.GETXMLTYPE (L_CTX, DBMS_XMLGEN.NONE);

  L_NUM_ROWS := DBMS_XMLGEN.GETNUMROWSPROCESSED (L_CTX);

  DBMS_XMLGEN.CLOSECONTEXT (L_CTX);

  CLOSE P_REF_CURSOR;

  IF L_NUM_ROWS > 0 THEN
    -- PERFORM THE XSL TRANSFORMATION
    L_JSON := L_XML.TRANSFORM (XMLTYPE(GET_XML_TO_JSON_STYLESHEET));
    L_RETURNVALUE := L_JSON.GETCLOBVAL();
  ELSE
    L_RETURNVALUE := G_JSON_NULL_OBJECT;
  END IF;

  L_RETURNVALUE := DBMS_XMLGEN.CONVERT (L_RETURNVALUE, DBMS_XMLGEN.ENTITY_DECODE);

  RETURN L_RETURNVALUE;

END REF_CURSOR_TO_JSON;


FUNCTION SQL_TO_JSON (P_SQL IN VARCHAR2,
                      P_PARAM_NAMES IN T_PC_STR_ARRAY := NULL,
                      P_PARAM_VALUES IN T_PC_STR_ARRAY := NULL,
                      P_MAX_ROWS IN NUMBER := NULL,
                      P_SKIP_ROWS IN NUMBER := NULL) RETURN CLOB
AS
  L_CTX         DBMS_XMLGEN.CTXHANDLE;
  L_NUM_ROWS    PLS_INTEGER;
  L_XML         XMLTYPE;
  L_JSON        XMLTYPE;
  L_RETURNVALUE CLOB;
BEGIN

  /*

  PURPOSE:    GENERATE JSON FROM SQL STATEMENT

  REMARKS:

  WHO     DATE        DESCRIPTION
  ------  ----------  -------------------------------------
  VALK    10.01.2018  CREATED - WINTHOR
  SAN
  DRO

  */


  L_CTX := DBMS_XMLGEN.NEWCONTEXT (P_SQL);

  DBMS_XMLGEN.SETNULLHANDLING (L_CTX, DBMS_XMLGEN.EMPTY_TAG);

  -- BIND VARIABLES, IF ANY
  IF P_PARAM_NAMES IS NOT NULL THEN

    FOR I IN 1..P_PARAM_NAMES.COUNT LOOP
      DBMS_XMLGEN.SETBINDVALUE (L_CTX, P_PARAM_NAMES(I), NVL(P_PARAM_VALUES(I), ''));
    END LOOP;

  END IF;

  -- FOR PAGINATION

  IF P_MAX_ROWS IS NOT NULL THEN
    DBMS_XMLGEN.SETMAXROWS (L_CTX, P_MAX_ROWS);
  END IF;

  IF P_SKIP_ROWS IS NOT NULL THEN
    DBMS_XMLGEN.SETSKIPROWS (L_CTX, P_SKIP_ROWS);
  END IF;

  -- GET THE XML CONTENT
  L_XML := DBMS_XMLGEN.GETXMLTYPE (L_CTX, DBMS_XMLGEN.NONE);

  L_NUM_ROWS := DBMS_XMLGEN.GETNUMROWSPROCESSED (L_CTX);

  DBMS_XMLGEN.CLOSECONTEXT (L_CTX);

  -- PERFORM THE XSL TRANSFORMATION
  IF L_NUM_ROWS > 0 THEN
    L_JSON := L_XML.TRANSFORM (XMLTYPE(GET_XML_TO_JSON_STYLESHEET));
    L_RETURNVALUE := L_JSON.GETCLOBVAL();
    L_RETURNVALUE := DBMS_XMLGEN.CONVERT (L_RETURNVALUE, DBMS_XMLGEN.ENTITY_DECODE);
  ELSE
    L_RETURNVALUE := G_JSON_NULL_OBJECT;
  END IF;

  RETURN L_RETURNVALUE;

END SQL_TO_JSON;


END PKG_JSON_UTIL; 
