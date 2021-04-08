<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:fmp="http://www.filemaker.com/fmpdsoresult">
    <xsl:output method="xml" indent="yes" name="xml-format"/>
    <xsl:strip-space elements="*"/>
    <!-- 070816 - Test using separate Names file -->
    <!-- Note: Names.xml file must be up-to-date, that is recently exported if it is to be properly -->
    <!-- in sync with the exported Image records -->
    <!-- how do we export the Names file, again? (carlj, 111022) -->
    <!-- <xsl:variable name="names" select="document('/Users/carlj/Developer/XML/IRIS/names_111024.xml')"/> -->
    <xsl:template match="fmp:FMPDSORESULT">
        <!-- xmlns:dc="http://purl.org/dc/elements/1.1/" -->
        <!-- Takes flattened xml output from images and works to create an image record for each slide -->
        <!-- Apply to each corresponding image record -->
        <!-- Gather image file name and use as directory name -->
        <!-- Test and write each record to a separate dublin_core.xml
            file in each dir -->
        <!--  -->
        <!-- Change Log -->
        <!-- 070529, added check for more than one Label_View_Type for dc.description field -->
        <!-- Add extra whitespace if more than one Label_View_Type -->
        <!-- Change Log -->
        <!-- 070710, Revised metadata fields -->
        <!-- But we can put Role and Extant on a separate line after creator -->
        <!-- 071107 - Improved understanding of Work_Agents and better export strategy from FMP? -->
        <!-- Work_Agents::Names_ID, Work_Agents::c_Role, Work_Agents::Extent, Work_Agents::Attribution, Work_Agents::Probability

            Put alternative creator names into dc:contributor.illustrator for now

            dc:date.created = date_type
            dc:date = actual date (or is it vice-versa)
        -->
        <!-- (081118, carlj) Build Kepes-Lynch collection metadata for Dome ingest -->
        <!-- added Vendor_Code and Digital_Filename fields which contains the PDF/TIFF file basenames -->
        <!-- TODO: let's set the output directory dynamically from the command line (carlj, 111025) -->

        <!-- Revisions 3-20-2012: 
        Decision was made to drop the local custom MIT namespace and use only dc and limited vra instead -->

        <!-- Simplify CCO_Location_Display template to use contains(., 'Repository') to set dc:publisher.institution (carlj, 120516) -->

        <!-- Updated 12-03-2013 -->
        <!-- added check for type = 'alteration' in getIssueDate and getCreationDate templates -->

        <xsl:for-each select="fmp:ROW">

            <!--
            <xsl:variable name="output_dir"
                select="concat('/Users/rvcdigital/forDSpaceUpload/',
                fmp:Image_No.)"/>
                -->
            <!--
            <xsl:variable name="output_dir"
                select="concat('/Users/carlj/Developer/XML/SDS/Problems/iris_missing_dates+bad_metadata_test_sips_2014/', fmp:Image_No.)"/> -->

            <!--   <xsl:variable name="output_dir"
            select="concat('/Users/carlj/Developer/XML/PerceptualFormOfTheCity/updated_sips/', fmp:Image_No.)"/> -->

            <!-- 
            <xsl:variable name="output_dir"
                select="concat('/Users/carlj/Desktop/IRIS/2012/', fmp:Image_No.)"/>  -->

            <!--  <xsl:variable name="output_dir"
                select="concat('/Users/carlj/Developer/XML/Dome/Problems/Dates_and_Subjects_2007/110182-110707/sips/', fmp:Image_No.)"/> -->

            <!-- <xsl:variable name="output_dir"
                select="concat('/Users/carlj/Developer/XML/Dome/Problems/Dates_and_Subjects_2007/108090-108779/sips/', fmp:Image_No.)"/> -->

           <!-- <xsl:variable name="output_dir"
                select="concat('/Users/carlj/Developer/XML/Dome/Problems/CypressPaphos_work_144221/sips/', fmp:Image_No.)"/> -->

            <xsl:variable name="output_dir"
                select="concat('/Users/carlj/Developer/XML/Dome/Problems/November/sips/', fmp:Image_No.)"/>
            
            <xsl:result-document href="{$output_dir}/dublin_core.xml" format="xml-format">
                <dublin_core>
                    <xsl:message>
                        <xsl:variable name="count" select="position()"/> Record count =
                            <xsl:value-of select="$count"/>
                    </xsl:message>

                    <xsl:message>dc:identifier = <xsl:value-of select="fmp:Image_No."
                        /></xsl:message>

                    <!-- dc:creator when available, otherwise set to 'Unknown' -->
                    <xsl:apply-templates select="fmp:pref_Name" mode="DATA"/>

                    <xsl:apply-templates select="fmp:pref_Name" mode="simple"/>

                    <!-- dc.date.issued -->
                    <xsl:call-template name="getIssueDate">
                        <xsl:with-param name="counter">1</xsl:with-param>
                        <xsl:with-param name="match_counter">0</xsl:with-param>
                    </xsl:call-template>

                    <!-- check for empty Start_Year string; set dc:date.issued to Unavailable -->
                    <xsl:apply-templates select="fmp:Start_Year" mode="empty"/>

                    <!-- dc.date -->
                    <xsl:call-template name="getCreationDate">
                        <!-- fmp:Type = 'creation' -->
                        <!-- <xsl:with-param name="counter"><xsl:value-of select="count(fmp:Date/fmp:DATA)"></xsl:value-of></xsl:with-param> -->
                        <xsl:with-param name="counter">1</xsl:with-param>
                        <xsl:with-param name="match_counter">0</xsl:with-param>
                    </xsl:call-template>

                    <!-- check for empty Start_Year string; set dc:date to Unavailable -->
                    <xsl:apply-templates select="fmp:Date" mode="empty"/>

                    <!-- dc:coverage.temporal -->
                    <!-- Note: sometimes the creation date: is not in first position so iterate until we find one -->
                    <xsl:call-template name="getCoverageTemporal">
                        <xsl:with-param name="counter">1</xsl:with-param>
                        <xsl:with-param name="match_counter">0</xsl:with-param>
                    </xsl:call-template>

                    <!-- dc.title, dc.title.alternative: primary and alternative titles -->
                    <xsl:call-template name="getTitle">
                        <xsl:with-param name="counter">1</xsl:with-param>
                        <xsl:with-param name="primary_title_match_counter">1</xsl:with-param>
                    </xsl:call-template>

                    <!-- returns handle url if IRIS has been updated with Dome URL's -->
                    <!-- <xsl:apply-templates select="fmp:Filepath/fmp:DATA[1]"/> -->

                    <!-- (carlj, 140408) -->
                    <!-- <xsl:apply-templates select="fmp:Filepath/fmp:DATA" mode="multi"/>  -->

                    <xsl:call-template name="getFilepath">
                        <!-- dynamically get count of how many occurrences of filepath we need to iterate through -->
                        <xsl:with-param name="counter">
                            <xsl:value-of select="count(fmp:Filepath/fmp:DATA)"/>
                        </xsl:with-param>
                        <xsl:with-param name="match_counter">0</xsl:with-param>
                    </xsl:call-template>

                    <xsl:apply-templates
                        select="fmp:Image_No. | fmp:Description | fmp:Subject_Term | fmp:cPref_Subject_Term"/>
                    <xsl:apply-templates select="fmp:Image_Copyright | fmp:Image_Rights_Statement"/>
                    <xsl:apply-templates select="fmp:Work_No."/>

                    <!-- dc.description -->
                    <xsl:apply-templates select="fmp:View_Title"/>

                    <xsl:apply-templates select="fmp:Vendor_Code"/>

                    <!-- dc:format.medium -->
                    <xsl:apply-templates select="fmp:Material_Name"/>

                    <!-- dc:type, set default to 'image' for RVC materials -->
                    <xsl:call-template name="localFixedType"/>

                    <!-- dc:contributor.display -->
                    <xsl:apply-templates select="fmp:Free_Text_Agents_Display"
                        mode="contributorDisplay"/>

                    <!--  dc:coverage.spatial and dc:publication.institituion -->
                    <!-- TEST dc:publisher.institution if field contains 'Repository' string, otherwise dc:coverage.spatial -->
                    <!-- Alternatively, we could used CCO_Locations_Display but the result is the same, I believe -->
                    <xsl:apply-templates select="fmp:CCO_Location_Display" mode="contains"/>

                    <!-- dc.format.extent -->
                    <xsl:apply-templates select="fmp:CCO_Measurement_Display"/>

                </dublin_core>
            </xsl:result-document>


            <!-- Create VRA Core metadata file (carlj, 111129) -->
            <xsl:result-document href="{$output_dir}/metadata_vra.xml" format="xml-format">
                <!-- VRA core related fields -->
                <dublin_core schema="vra">

                    <!-- commented out fmp:WorkType, 130906 -->
                    <!-- <xsl:apply-templates select="fmp:WorkType"/> -->

                    <!-- add new worktype checks (carlj, 130904) -->

                    <xsl:message>Processing vra:worktype from fmp:cWorktype....</xsl:message>

                    <xsl:apply-templates select="fmp:cWorktype"/>

                    <xsl:apply-templates select="fmp:Technique_Name/fmp:DATA"/>

                    <xsl:apply-templates select="fmp:cPref_Culture_Name"/>
                </dublin_core>
            </xsl:result-document>

        </xsl:for-each>
    </xsl:template>

    <xsl:template match="fmp:cPreferred_Title/fmp:DATA[position()=1]" mode="data">
        <xsl:for-each select=".">
            <dcvalue element="title" identifier="none">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:for-each>
    </xsl:template>

    <!-- fmp:Filepath maps to dc.identifier.uri -->
    <xsl:template match="fmp:Filepath/fmp:DATA" mode="test">
        <xsl:message> In template Filepath match, mode=test </xsl:message>
        <xsl:for-each select=".">
            <!--  <xsl:if
                test="string(.) and .[position()] or .[position()+1]">
                <dcvalue element="identifier" qualifier="uri">
                    <xsl:value-of select="."/>
                </dcvalue>
            </xsl:if> -->

            <!-- <xsl:if test="string(.)">
                <dcvalue element="identifier" qualifier="uri">
                    <xsl:value-of select="."/>
                </dcvalue>
            </xsl:if>
            -->

            <xsl:choose>

                <xsl:when test="string(.) and count &lt; 2">
                    <dcvalue element="identifier" qualifier="uri">
                        <xsl:value-of select="."/>
                    </dcvalue>
                </xsl:when>

                <xsl:when test="string(.)">
                    <dcvalue element="identifier" qualifier="uri">
                        <xsl:value-of select="."/>
                    </dcvalue>
                </xsl:when>

            </xsl:choose>
        </xsl:for-each>

    </xsl:template>


    <!-- fmp:Filepath maps to dc.identifier.uri -->
    <!-- In case of multiple Filepath entries (140328, carlj) 
    <xsl:template match="fmp:Filepath/fmp:DATA[1]">
        <xsl:if test="string(.)">
            <dcvalue element="identifier" qualifier="uri">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template> -->

    <!-- fmp:Filepath maps to dc.identifier.uri -->
    <!-- In case of multiple Filepath entries (140328, carlj) -->
    <xsl:template match="fmp:Filepath/fmp:DATA" mode="multi">
        <xsl:if test="string(.)">
            <dcvalue element="identifier" qualifier="uri">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

    <xsl:template name="getFilepath">
        <xsl:param name="counter"/>
        <xsl:param name="match_counter"/>
        <xsl:message>Entering getFilepath() just after counter parameter is set to <xsl:value-of
                select="$counter"/></xsl:message>
        <xsl:message>match_counter = <xsl:value-of select="$match_counter"/></xsl:message>

        <xsl:variable name="filepath_count" select="count(fmp:Filepath/fmp:DATA)"/>
        <xsl:message>In getFilepath() filepath_count = <xsl:value-of select="$filepath_count"
            /></xsl:message>

        <xsl:if test="$counter &lt;= $filepath_count and ($match_counter &lt;= 1)">

            <xsl:variable name="filepath" select="fmp:Filepath/fmp:DATA[position()=$counter]"/>
            <xsl:message>Filepath = <xsl:value-of select="$filepath"/></xsl:message>
            <xsl:message>position = <xsl:value-of select="$counter"/></xsl:message>

            <xsl:if test="string($filepath)">
                <xsl:message>If filepath test = string....<xsl:value-of select="$filepath"
                    /></xsl:message>
                <dcvalue element="identifier" qualifier="uri">
                    <xsl:value-of select="$filepath"/>
                </dcvalue>
                <xsl:message>If filepath test = string....<xsl:value-of select="$filepath"
                    /></xsl:message>
            </xsl:if>

            <xsl:message>Will call getFilepath() again</xsl:message>
            <xsl:call-template name="getFilepath">
                <xsl:with-param name="counter" select="$counter + 1"/>
                <xsl:with-param name="match_counter" select="$match_counter + 1"/>
            </xsl:call-template>

        </xsl:if>

    </xsl:template>

    <!-- If fmp:pref_Name is blank, then use "Unknown" instead -->
    <xsl:template match="fmp:pref_Name/fmp:DATA" mode="DATA">
        <!-- <xsl:template match="fmp:pref_Name/fmp:DATA | fmp:pref_Name"> -->
        <xsl:message>pref_Name = <xsl:value-of select="."/></xsl:message>
        <xsl:choose>
            <xsl:when test="string(.)">
                <xsl:element name="dcvalue">
                    <xsl:attribute name="element">creator</xsl:attribute>
                    <xsl:attribute name="qualifier">none</xsl:attribute>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="dcvalue">
                    <xsl:attribute name="element">creator</xsl:attribute>
                    <xsl:attribute name="qualifier">none</xsl:attribute>
                    <xsl:text>Unknown</xsl:text>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- dc:creator fallback -->
    <!-- Same as above template, except sometimes a single fmp:pref_Name field is used without the DATA tag -->
    <xsl:template match="fmp:pref_Name" mode="simple">
        <xsl:message>pref_Name = <xsl:value-of select="."/></xsl:message>
        <xsl:choose>
            <xsl:when test="not(string(../fmp:pref_Name/fmp:DATA[position()=1])) and string(.)">
                <xsl:element name="dcvalue">
                    <xsl:attribute name="element">creator</xsl:attribute>
                    <xsl:attribute name="qualifier">none</xsl:attribute>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:when>
            <xsl:when test="not(string(../fmp:pref_Name/fmp:DATA[position()=1])) and not(string(.))">
                <xsl:element name="dcvalue">
                    <xsl:attribute name="element">creator</xsl:attribute>
                    <xsl:attribute name="qualifier">none</xsl:attribute>
                    <xsl:text>Unknown</xsl:text>
                </xsl:element>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <!-- exported from fmp:Names_Names::Name -->
    <!-- not using this for now -->
    <xsl:template match="fmp:Name/fmp:DATA">
        <xsl:for-each select=".">
            <dcvalue element="creator" qualifier="none">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:for-each>
    </xsl:template>



    <!-- (carlj, 111021) -->
    <xsl:template match="fmp:Description">
        <xsl:if test="string(.)">
            <dcvalue element="description" qualifier="none">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

    <!-- dc:subject from cPref_Subject_Term w/IRIS2008 (carlj, 130625) -->
    <xsl:template match="fmp:cPref_Subject_Term/fmp:DATA">
        <dcvalue element="subject" qualifier="none">
            <xsl:value-of select="normalize-space(.)"/>
        </dcvalue>
    </xsl:template>

    <!-- Simplified dc:subject (carlj, 111021) -->
    <xsl:template match="fmp:Subject_Term/fmp:DATA">
        <dcvalue element="subject" qualifier="none">
            <xsl:value-of select="normalize-space(.)"/>
        </dcvalue>
    </xsl:template>


    <xsl:template match="fmp:Work_No./fmp:DATA">
        <dcvalue element="relation" qualifier="ispartof">
            <xsl:value-of select="."/>
        </dcvalue>
    </xsl:template>

    <!-- vra:workType -->
    <!-- type of work, e.g. painting, sculpture, etc. -->
    <xsl:template match="fmp:WorkType/fmp:DATA">
        <dcvalue element="worktype" qualifier="none">
            <xsl:value-of select="."/>
        </dcvalue>
    </xsl:template>

    <!-- vra.worktype (carlj, 130904) -->
    <!-- 'separator' puts a comma between multiple terms -->
    <xsl:template match="fmp:cWorktype">
        <dcvalue element="worktype" qualifier="none">
            <xsl:value-of select="fmp:DATA" separator=", "/>
        </dcvalue>
    </xsl:template>


    <!-- dc.type set to fixed value: "Image" (carlj, 111219) -->
    <xsl:template name="localFixedType">
        <dcvalue element="type" qualifier="none">
            <xsl:text>Image</xsl:text>
        </dcvalue>
    </xsl:template>


    <!-- NOTE: this should now go to dc:format.medium.... (carlj, 120321) -->
    <!-- <vra:materialSet> -->
    <!-- Format medium and support -->
    <!-- vra support and material go to format.medium -->
    <xsl:template match="fmp:Material_Name/fmp:DATA">
        <xsl:if test="string(.)">
            <dcvalue element="format" qualifier="medium">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

    <!-- dc:format.support -->
    <xsl:template match="fmp:Material_Type">
        <xsl:if test="string(.)">
            <dcvalue element="format" qualifier="medium">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

    <!-- vra.technique -->
    <xsl:template match="fmp:Technique_Name/fmp:DATA">
        <xsl:if test="string(.)">
            <dcvalue element="technique" qualifier="none">
                <xsl:value-of select="." separator=", "/>
            </dcvalue>
        </xsl:if>
    </xsl:template>
    <!-- </vra:materialSet> -->


    <!--- <vra:rightsSet> -->
    <!-- Will become dc.rights  (carlj, 111219) -->
    <xsl:template match="fmp:Image_Copyright">
        <xsl:if test="string(.)">
            <dcvalue element="rights" qualifier="none">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

    <xsl:template match="fmp:Image_Rights_Statement">
        <xsl:if test="string(.)">
            <dcvalue element="rights" qualifier="access">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

    <!-- Image_No -->
    <!-- IRIS image id number -->
    <!-- dc.identifier, use format-number() to pad with leading zero's out to 6 digits, if necessary -->
    <xsl:template match="fmp:Image_No.">
        <dcvalue element="identifier" qualifier="none">
            <xsl:value-of select="format-number(., '000000')"/>
        </dcvalue>
    </xsl:template>


    <!-- TODO: what if we have multiple Start/End Years? This can often be the case -->
    <!-- latest revision assigns start_year/end_year to dc:date.issued ONLY (carlj, 120503) -->
    <xsl:template match="fmp:Start_Year/fmp:DATA" mode="dc_date">
        <xsl:param name="counter"/>
        <xsl:variable name="start_year" select="."/>
        <xsl:variable name="end_year" select="../../fmp:End_Year/fmp:DATA[position()=1]"/>

        <xsl:message>Selected Start_Year = <xsl:value-of select="$start_year"/></xsl:message>
        <xsl:message>Selected End_Year = <xsl:value-of select="$end_year"/></xsl:message>

        <xsl:choose>
            <xsl:when test="string($start_year) and string($end_year) and $start_year != $end_year">
                <dcvalue element="date" qualifier="none">
                    <xsl:value-of select="concat($start_year, '-', $end_year)"/>
                </dcvalue>
            </xsl:when>

            <xsl:when test="string($start_year) and string($end_year) and $start_year = $end_year">
                <dcvalue element="date" qualifier="none">
                    <xsl:value-of select="$start_year"/>
                </dcvalue>
            </xsl:when>

            <xsl:otherwise>
                <dcvalue element="date" qualifier="none">
                    <xsl:value-of select="$start_year"/>
                </dcvalue>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- dc:date.issued -->
    <!-- TODO: what if we have multiple Start/End Years? This can often be the case but our guidelines say to use only one -->
    <!-- latest revision assigns first occurance of start_year/end_year to dc:date.issued  (carlj, 120523) -->
    <!-- TODO:  (carlj, 140318) can we check for BC dates and format accordingly? -->
    <xsl:template name="getIssueDate">
        <xsl:param name="counter"/>
        <xsl:param name="match_counter"/>
        <xsl:message>Entering getIssueDate() just after param name counter is set = <xsl:value-of
                select="$counter"/></xsl:message>
        <xsl:message>match_counter = <xsl:value-of select="$match_counter"/></xsl:message>

        <xsl:variable name="test_count" select="count(distinct-values(fmp:Start_Year/fmp:DATA))"/>
        <xsl:message>In getIssueDate() test_count = <xsl:value-of select="$test_count"
            /></xsl:message>

        <xsl:if test="$counter &lt;= $test_count and ($match_counter &lt;= 1)">

            <xsl:message>getIssueDate(), in foreach counter = <xsl:value-of select="$counter"
                /></xsl:message>
            <xsl:variable name="start_year" select="fmp:Start_Year/fmp:DATA[position()=$counter]"/>
            <xsl:variable name="end_year" select="fmp:End_Year/fmp:DATA[position()=$counter]"/>
            <xsl:variable name="type" select="fmp:Type/fmp:DATA[position()=$counter]"/>

            <xsl:message>Selected Start_Year = <xsl:value-of select="$start_year"/></xsl:message>
            <xsl:message>Selected End_Year = <xsl:value-of select="$end_year"/></xsl:message>
            <xsl:message>Selected Type = <xsl:value-of select="$type"/></xsl:message>

            <xsl:if
                test="($start_year != $end_year) and (($type='creation') or ($type='Creation') or ($type='publication') or ($type='Publication') or ($type='other') or ($type='Other') or ($type='alteration') or ($type='Alteration'))">
                <xsl:message>start_year != end_year and type = <xsl:value-of select="$type"
                    /></xsl:message>
                <dcvalue element="date" qualifier="issued">
                    <xsl:value-of select="concat($start_year, '-', $end_year)"/>
                </dcvalue>
            </xsl:if>

            <xsl:if
                test="($start_year = $end_year) and (($type='creation') or ($type='Creation') or ($type='publication') or ($type='Publication') or ($type='other') or ($type='Other') or ($type='alteration') or ($type='Alteration'))">
                <xsl:message>start_year = end_year and type = <xsl:value-of select="$type"
                    /></xsl:message>
                <dcvalue element="date" qualifier="issued">
                    <xsl:value-of select="$start_year"/>
                </dcvalue>
            </xsl:if>

            <xsl:message>Will call getIssueDate() again</xsl:message>
            <xsl:call-template name="getIssueDate">
                <xsl:with-param name="counter" select="$counter + 1"/>
                <xsl:with-param name="match_counter" select="$match_counter + 1"/>
            </xsl:call-template>

        </xsl:if>

    </xsl:template>


    <!-- if there's no fmp:Start_Year date information at all, set dc:date.issued to 'Unavailable' (carlj, 120521) -->
    <xsl:template match="fmp:Start_Year" mode="empty">
        <xsl:message>Test for empty Start_Year</xsl:message>
        <xsl:if test="not (string(.))">
            <xsl:message>fmp:Start_Year is empty, will set dc:date.issued to
                'Unavailable'</xsl:message>
            <dcvalue element="date" qualifier="issued">
                <xsl:text>Unavailable</xsl:text>
            </dcvalue>
        </xsl:if>
    </xsl:template>


    <!-- if there's no fmp:Start_Year date information at all, set BOTH dc:date.issued and dc:date to Unknown (carlj, 120521) -->
    <xsl:template match="fmp:Date" mode="empty">
        <xsl:message>Test for empty Start_Year</xsl:message>
        <xsl:if test="not (string(.))">
            <xsl:message>All Dates are empty, will set dc:date to 'Unavailable'</xsl:message>
            <dcvalue element="date" qualifier="none">
                <xsl:text>Unavailable</xsl:text>
            </dcvalue>
        </xsl:if>
    </xsl:template>


    <!-- dc:date.none -->
    <!-- TODO: if we have multiple dates of type='creation' use only the first occurrence (carlj, 120529) -->
    <xsl:template name="getCreationDate">
        <xsl:param name="counter"/>
        <xsl:param name="match_counter"/>
        <xsl:message>Entering getCreationDate() just after param name counter is set = <xsl:value-of
                select="$counter"/></xsl:message>
        <xsl:message>match_counter = <xsl:value-of select="$match_counter"/></xsl:message>

        <!-- tells us how many fmp:date fields are present -->
        <xsl:variable name="test_count" select="count(distinct-values(fmp:Date/fmp:DATA))"/>
        <xsl:message>In getCreationDate() test_count = <xsl:value-of select="$test_count"
            /></xsl:message>

        <xsl:message>counter = <xsl:value-of select="$counter"/></xsl:message>
        <xsl:if test="$counter &lt;= $test_count and ($match_counter &lt;= 1)">

            <xsl:message>getCreationDate(), in foreach counter = <xsl:value-of select="$counter"
                /></xsl:message>
            <xsl:variable name="date" select="fmp:Date/fmp:DATA[position()=$counter]"/>
            <xsl:variable name="type" select="fmp:Type/fmp:DATA[position()=$counter]"/>

            <xsl:message>Selected creation date = <xsl:value-of select="$date"/></xsl:message>
            <xsl:message>Selected date Type = <xsl:value-of select="$type"/></xsl:message>

            <xsl:if
                test="string($date) and (($type='creation') or ($type='Creation') or ($type='publication') or ($type='Publication') or ($type='other') or ($type='Other') or ($type='alteration') or ($type='Alteration'))">
                <xsl:message>date = <xsl:value-of select="$date"/> and type = <xsl:value-of
                        select="$type"/></xsl:message>
                <dcvalue element="date" qualifier="none">
                    <xsl:value-of select="$date"/>
                </dcvalue>
            </xsl:if>

            <xsl:message>Will call getCreationDate() again</xsl:message>
            <xsl:call-template name="getCreationDate">
                <xsl:with-param name="counter" select="$counter + 1"/>
                <xsl:with-param name="match_counter" select="$match_counter + 1"/>
            </xsl:call-template>

        </xsl:if>

    </xsl:template>


    <!-- dc:coverage.temporal -->
    <!-- TODO: what if we have multiple Start/End Years? This can often be the case but our guidelines say to use only one -->
    <!-- latest revision assigns first occurance of start_year/end_year to dc:date.issued  (carlj, 120523) -->
    <xsl:template name="getCoverageTemporal">
        <xsl:param name="counter"/>
        <xsl:param name="match_counter"/>
        <xsl:message>Entering getCoverageTemporal() just after param name counter is set =
                <xsl:value-of select="$counter"/></xsl:message>
        <xsl:message>match_counter = <xsl:value-of select="$match_counter"/></xsl:message>

        <xsl:variable name="test_count"
            select="count(distinct-values(fmp:CCO_Date_Display/fmp:DATA))"/>
        <xsl:message>In getCoverageTemporal() test_count = <xsl:value-of select="$test_count"
            /></xsl:message>

        <xsl:if test="$counter &lt;= $test_count and ($match_counter &lt;= 1)">

            <xsl:message>getCoverageTemporal(), in foreach counter = <xsl:value-of select="$counter"
                /></xsl:message>
            <xsl:variable name="cco_date_display"
                select="fmp:CCO_Date_Display/fmp:DATA[position()=$counter]"/>

            <xsl:message>Selected CCO_Date_Display = <xsl:value-of select="$cco_date_display"
                /></xsl:message>

            <xsl:if
                test="string($cco_date_display) and (contains($cco_date_display, 'date:') or contains($cco_date_display, 'Date:'))">
                <xsl:message>CCO_Date_Display found and contains 'date:' string</xsl:message>
                <dcvalue element="coverage" qualifier="temporal">
                    <xsl:value-of select="$cco_date_display"/>
                </dcvalue>
            </xsl:if>

            <xsl:message>Will call getCoverageTemporal() again</xsl:message>
            <xsl:call-template name="getCoverageTemporal">
                <xsl:with-param name="counter" select="$counter + 1"/>
                <xsl:with-param name="match_counter" select="$match_counter + 1"/>
            </xsl:call-template>

        </xsl:if>
    </xsl:template>


    <!-- IRIS Work_No. to dc:relation.ispartof -->
    <!-- (120321, carlj) -->
    <xsl:template match="fmp:Related_Work_No.">
        <xsl:if test="string(.)">
            <dcvalue element="relation" qualifier="ispartof">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>


    <!-- see above!! (120321, carlj) -->
    <xsl:template match="fmp:Work_No./fmp:DATA" mode="otherIdentifier">
        <!-- test for duplicate (carlj, 120209) -->
        <xsl:if test="string(.) and .[not(.=preceding-sibling::fmp:DATA)]">
            <dcvalue element="relation" qualifier="ispartof">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

    <xsl:template match="fmp:cPreferred_Title/fmp:DATA[position()=1]">
        <xsl:for-each select=".">
            <dcvalue element="title" identifier="none">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:for-each>
    </xsl:template>


    <!-- Title primary/variant (carlj, 120206) -->
    <!-- dc:title, dc.title.alternative -->
    <!-- TODO: check to make sure primary and alternative titles are not the same (carlj, 120207) -->
    <xsl:template match="fmp:Title/fmp:DATA">
        <xsl:variable name="titleQualifierCurrentPosition" select="position()"/>
        <!-- <xsl:variable name="titleString" select="fmp:Title"/> -->
        <xsl:message>In match fmp:Title - DC Title Primary/Variant, current title: <xsl:value-of
                select="."/></xsl:message>
        <xsl:message>Value of position() = <xsl:value-of select="position()"/></xsl:message>

        <xsl:message>Title Qualifier: <xsl:value-of
                select="../../fmp:Title_Qualifier/fmp:DATA[$titleQualifierCurrentPosition]"
            /></xsl:message>
        <xsl:if test="string(.)">
            <xsl:element name="dcvalue">
                <xsl:attribute name="element">title</xsl:attribute>
                <xsl:attribute name="qualifier">
                    <xsl:choose>
                        <xsl:when
                            test="../../fmp:Title_Qualifier/fmp:DATA[$titleQualifierCurrentPosition]='Variant' or ../../fmp:Title_Qualifier/fmp:DATA[$titleQualifierCurrentPosition]='' and . != ../../fmp:cPreferred_Title">
                            <xsl:text>alternative</xsl:text>
                        </xsl:when>
                        <xsl:when
                            test="../../fmp:Title_Qualifier/fmp:DATA[$titleQualifierCurrentPosition]='Primary'">
                            <!-- changed to _alternative_ to allow or display_title above, which now takes precedence -->
                            <!-- 070705, no longer using display_title, so use 'none' here -->
                            <xsl:text>none</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>
                <xsl:message>Current title value: <xsl:value-of select="."/></xsl:message>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:if>
    </xsl:template>

    <!-- check to make sure primary and alternative titles are not the same (carlj, 120207) -->
    <xsl:template name="getTitle">
        <xsl:param name="counter"/>
        <xsl:param name="primary_title_match_counter"/>

        <xsl:message>Entering getTitle() just after param name counter is set = <xsl:value-of
                select="$counter"/></xsl:message>
        <xsl:message>Primary Title match_counter = <xsl:value-of
                select="$primary_title_match_counter"/></xsl:message>

        <xsl:variable name="title" select="fmp:Title/fmp:DATA[position()=$counter]"/>
        <xsl:variable name="title_qualifier"
            select="fmp:Title_Qualifier/fmp:DATA[position()=$counter]"/>

        <xsl:variable name="title_count" select="count(distinct-values(fmp:Title/fmp:DATA))"/>
        <xsl:message>In getTitle() total title_count = <xsl:value-of select="$title_count"
            /></xsl:message>


        <xsl:if test="string($title) and ($counter &lt;= $title_count)">
            <xsl:element name="dcvalue">
                <xsl:attribute name="element">title</xsl:attribute>
                <xsl:attribute name="qualifier">
                    <!-- set attribute -->
                    <xsl:choose>
                        <xsl:when test="string($title) and $title_qualifier='Variant'">
                            <xsl:text>alternative</xsl:text>
                        </xsl:when>
                        <xsl:when test="string($title) and not(string($title_qualifier))">
                            <xsl:text>alternative</xsl:text>
                        </xsl:when>
                        <xsl:when
                            test="(string($title)) and ($title_qualifier='Primary') and ($primary_title_match_counter &gt; 1)">
                            <xsl:text>alternative</xsl:text>
                        </xsl:when>
                        <xsl:when
                            test="string($title) and ($title_qualifier='Primary') and ($primary_title_match_counter &lt;= 1)">
                            <xsl:text>none</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>

                <xsl:message>Current title value: <xsl:value-of select="$title"/></xsl:message>
                <xsl:message>Current Title Qualifier: <xsl:value-of select="$title_qualifier"
                    /></xsl:message>
                <xsl:value-of select="$title"/>
            </xsl:element>

            <xsl:message>Will call getTitle() again</xsl:message>

            <xsl:choose>
                <xsl:when test="$title_qualifier = 'Primary'">
                    <xsl:call-template name="getTitle">
                        <xsl:with-param name="counter" select="$counter + 1"/>
                        <xsl:with-param name="primary_title_match_counter"
                            select="$primary_title_match_counter + 1"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="$title_qualifier='Variant' or not (string($title_qualifier))">
                    <xsl:call-template name="getTitle">
                        <xsl:with-param name="counter" select="$counter + 1"/>
                        <xsl:with-param name="primary_title_match_counter"
                            select="$primary_title_match_counter + 0"/>
                    </xsl:call-template>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
    </xsl:template>


    <xsl:template match="fmp:cPref_Culture_Name/fmp:DATA">
        <!-- test for duplicate node (carlj, 120209) -->
        <xsl:if test="string(.) and .[not(.=preceding-sibling::fmp:DATA)]">
            <dcvalue element="culturalContext" qualifier="none">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>


    <!-- This goes into local Dome dc:contributor.display field -->
    <!-- currently not calling this template (120208, carlj) -->
    <xsl:template match="fmp:Free_Text_Agents_Display/fmp:DATA">
        <dcvalue element="namesDisplay" qualifier="none">
            <xsl:value-of select="."/>
        </dcvalue>
    </xsl:template>


    <!-- NOTE: If Free_Text_Agents_Display is blank, then use "Unknown" instead -->
    <xsl:template match="fmp:Free_Text_Agents_Display/fmp:DATA" mode="contributorDisplay">

        <!-- filter duplicates (check to make sure this works) -->
        <xsl:if test="string(.) and .[not(.=preceding-sibling::fmp:DATA)]">
            <xsl:element name="dcvalue">
                <xsl:attribute name="element">contributor</xsl:attribute>
                <xsl:attribute name="qualifier">display</xsl:attribute>
                <xsl:value-of select="."/>
            </xsl:element>
        </xsl:if>
    </xsl:template>


    <!-- Revised dc.creator (carlj, 111020) -->
    <!-- we now have Name and Name_Type -->
    <!-- we want to limit these to Name_Type = preferred -->
    <xsl:template match="fmp:Name/fmp:DATA">
        <dcvalue element="creator" qualifier="none">
            <xsl:value-of select="."/>
        </dcvalue>
    </xsl:template>

    <!-- dc:coverage.temporal -->
    <xsl:template match="fmp:cPeriod_Pref_Name/fmp:DATA">
        <dcvalue element="coverage" qualifier="temporal">
            <xsl:value-of select="."/>
        </dcvalue>
    </xsl:template>


    <!-- dc:identifier.vendorcode -->
    <xsl:template match="fmp:Vendor_Code">
        <xsl:if test="string(.)">
            <dcvalue element="identifier" qualifier="vendorcode">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

    <!-- dc.description -->
    <!-- Match on View_Title as most significant descriptive info (carlj, 120206) -->
    <xsl:template match="fmp:View_Title">

        <!-- Take the first fmp:View_Title by default -->
        <xsl:variable name="tmp_view_title" select="."/>
        <xsl:variable name="tmp_label_view_type" select="../fmp:Label_View_Type/fmp:DATA[1]"/>
        <xsl:variable name="tmp_view_date" select="../fmp:View_Date"/>

        <xsl:choose>
            <xsl:when
                test="not(string($tmp_label_view_type)) and not(string($tmp_view_title)) and not(string($tmp_view_date))">
                <!-- values are empty, do nothing -->
            </xsl:when>

            <xsl:otherwise>
                <xsl:element name="dcvalue">
                    <xsl:attribute name="element">description</xsl:attribute>
                    <xsl:attribute name="qualifier">none</xsl:attribute>

                    <xsl:value-of select="$tmp_label_view_type"/>

                    <xsl:if test="string($tmp_view_title)">
                        <xsl:value-of select="concat(', ', $tmp_view_title)"/>
                    </xsl:if>

                    <xsl:if test="string($tmp_view_date)">
                        <xsl:value-of select="concat(', ', $tmp_view_date)"/>
                    </xsl:if>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- dc:coverage.spatial and dc:publisher.institution -->
    <!-- Map to dc:coverage.spatial if does not contain 'Repository' -->
    <!-- check for duplicate dc:coverage.spatial elements (carlj, 120518) -->
    <!-- <xsl:if test="string(.) and .[not(.=preceding-sibling::fmp:DATA)]"> -->
    <xsl:template match="fmp:CCO_Location_Display/fmp:DATA" mode="contains">
        <xsl:choose>
            <xsl:when test="contains(., 'Repository')">
                <xsl:message>Found 'Repository' string, map to dc:publisher.institution:
                        <xsl:value-of select="."/></xsl:message>
                <dcvalue element="publisher" qualifier="institution">
                    <xsl:value-of select="."/>
                </dcvalue>
            </xsl:when>
            <xsl:when
                test="not (contains(., 'Repository')) and .[not(.=preceding-sibling::fmp:DATA)] and string(.)">
                <xsl:message>No 'Repository' string found, map to dc:coverage.spatial: <xsl:value-of
                        select="."/></xsl:message>
                <dcvalue element="coverage" qualifier="spatial">
                    <xsl:value-of select="."/>
                </dcvalue>
            </xsl:when>
        </xsl:choose>
    </xsl:template>


    <!-- Get Built Works Location -->
    <xsl:template match="fmp:Built_Work_No.">
        <dcvalue element="coverage" qualifier="spatial">
            <xsl:value-of
                select="concat(../fmp:Title/fmp:DATA[1], ', ',
                ../fmp:Geog_Place_Name/fmp:DATA[1])"
            />
        </dcvalue>
    </xsl:template>


    <!-- CCO_Measurement_Display for dc:format.extent -->
    <xsl:template match="fmp:CCO_Measurement_Display/fmp:DATA">
        <xsl:if test="string(.)">
            <dcvalue element="format" qualifier="extent">
                <xsl:value-of select="."/>
            </dcvalue>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
