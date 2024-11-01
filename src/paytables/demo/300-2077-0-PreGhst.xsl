<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>
			
			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable retrievePatternWins">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;					
					
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param bingoColumns String of Bingo Symbols.
					function formatJson(jsonContext, translations, prizeTable, convertedPrizeValues, prizeNames)
					{
						var scenario = getScenario(jsonContext);
						
						registerDebugText("Prize Table");
						
						var r = [];
						
						var winningNumbers = getWinningNumbers(scenario);
						var yourNumbers = getYourNumbers(scenario);
						
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');
						r.push('<tr class="tablehead">');
						r.push('<td>');
						r.push(getTranslationByName("luckyNumbers", translations));
						r.push('</td>');
						r.push('</tr>');
						r.push('<tr class="tablebody">');
						for(var i = 0; i < winningNumbers.length; i++){
							r.push('<td>');
							r.push(winningNumbers[i]);
							r.push('</td>');
						}
						r.push('</tr>');
						r.push('</table>');
						
						
						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');
						r.push('<tr class="tablehead">');
						r.push('<td>');
						r.push(getTranslationByName("yourNumbers", translations));
						r.push('</td>');
						r.push('</tr>');
						for(var i = 0; i < 4; i++){
							r.push('<tr class="tablebody">');
							for(var j = 0; j < 4; j++){
								r.push('<td>');
								r.push(handleMatch(yourNumbers[j + i*4],winningNumbers,convertedPrizeValues,translations));
								r.push(handleInstantWin(yourNumbers[j + i*4],winningNumbers,convertedPrizeValues,translations));
								r.push(handleMultiplier(yourNumbers[j + i*4],winningNumbers,convertedPrizeValues,translations));
								r.push(handleWinAll(yourNumbers[j + i*4],winningNumbers,convertedPrizeValues,translations));
								r.push('</td>');
							}
							r.push('</tr>');
						}
						r.push('</table>');
						
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
							{
								r.push('<tr>');
								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
								r.push('</td>');
								r.push('</tr>');
							}
							r.push('</table>');
						}

						return r.join('');
					}
					
					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}
					
					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}
					
					//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeTables, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeTableStrings = prizeTables.split("|");
						
						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								registerDebugText("Price Point " + pricePointList[i] + " table: " + prizeTableStrings[i]);
								return prizeTableStrings[i];
							}
						}
						
						return "";
					}
					
					function checkForLinesPattern(drawnNumbers, bingoCardData, linePatterns)
					{
						var linesAwarded = 0;
						for(var line = 0; line < linePatterns.length; ++line)
						{
							if(checkForExclusivePattern(drawnNumbers, bingoCardData, linePatterns[line]))
							{
								linesAwarded++;
								registerDebugText("Line Pattern Awarded(" + linesAwarded + "): " + linePatterns[line]);
							}
						}
						
						registerDebugText(linesAwarded);
						
						return linesAwarded;
					}
					
					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}
					
					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeLevelIndex(prizeNames,currPrize)
					{
						registerDebugText("Getting index of " + currPrize + " in " + prizeNames);
						var prizes = prizeNames.split(",");
						
						for(var i = 0; i < prizes.length; ++i)
						{
							if(prizes[i] === currPrize)
							{
								return i;
							}
						}
					}
					
					function getWinningNumbers(scenario){
						var luckyNumberStr = scenario.split('|')[0];
						var luckyNumbers = luckyNumberStr.split(',');
						return luckyNumbers;
					}
					
					function getYourNumbers(scenario){
						var luckyNumberStr = scenario.split('|')[1];
						var luckyNumbers = luckyNumberStr.split(',');
						return luckyNumbers;
					}
					
					function getPrizeValueForLevel(prizeLetter,convertedPrizeValues){
						var orderedPrizeLevels = "A,B,C,D,E,F,G,H";
						var prizeLevelIndex = parseInt(getPrizeLevelIndex(orderedPrizeLevels,prizeLetter));
						registerDebugText(prizeLevelIndex);
						var prizeValue = (convertedPrizeValues.substring(1)).split('|')[prizeLevelIndex];
						return prizeValue;
					}
					
					function handleMatch(yourNumber,winningNumbers,convertedPrizeValues,translations){
						var revealType = yourNumber.split(':')[0];
						if(revealType !== 'V' &&
							revealType !== 'W' &&
							revealType !== 'X' &&
							revealType !== 'Y' &&
							revealType !== 'Z'){
							
							var revealNumber = parseInt(revealType);
							var prizeLevel = yourNumber.split(':')[1];
							var prizeValue = getPrizeValueForLevel(prizeLevel,convertedPrizeValues);
							var matched = false;
							for(var i = 0; i < winningNumbers.length; i++){
								if(parseInt(winningNumbers[i])===revealNumber){
									matched = true;
								}
							}
							
							if(matched){
								return getTranslationByName("matched", translations) + " " + revealNumber + " " + prizeValue;
							}
							return revealNumber + " " + prizeValue;
						}
						return "";
					}
					
					function handleInstantWin(yourNumber,winningNumbers,convertedPrizeValues,translations){
						var revealType = yourNumber.split(':')[0];
						if(revealType === 'Y'){
							var prizeLevel = yourNumber.split(':')[1];
							var prizeValue = getPrizeValueForLevel(prizeLevel,convertedPrizeValues);
							return getTranslationByName("instantWin", translations) + " " + prizeValue;
						}
						return "";
					}
					
					function handleWinAll(yourNumber,winningNumbers,convertedPrizeValues,translations){
						var revealType = yourNumber.split(':')[0];
						if(revealType === 'Z'){
							var prizeLevel = yourNumber.split(':')[1];
							var prizeValue = getPrizeValueForLevel(prizeLevel,convertedPrizeValues);
							return getTranslationByName("winAll", translations) + " " + prizeValue;
						}
						return "";
					}
					
					function handleMultiplier(yourNumber,winningNumbers,convertedPrizeValues,translations){
						var revealType = yourNumber.split(':')[0];
						
						if(revealType === 'V'){
							var prizeLevel = yourNumber.split(':')[1];
							var prizeValue = getPrizeValueForLevel(prizeLevel,convertedPrizeValues);
							return getTranslationByName("2xmultiplier", translations) + " " + prizeValue;
						} else if(revealType === 'W'){
							var prizeLevel = yourNumber.split(':')[1];
							var prizeValue = getPrizeValueForLevel(prizeLevel,convertedPrizeValues);
							return getTranslationByName("5xmultiplier", translations) + " " + prizeValue;
						} else if(revealType === 'X'){
							var prizeLevel = yourNumber.split(':')[1];
							var prizeValue = getPrizeValueForLevel(prizeLevel,convertedPrizeValues);
							return getTranslationByName("10xmultiplier", translations) + " " + prizeValue;
						}
						return "";
					}
					
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="SignedData/Data/Outcome/OutcomeDetail/Payout" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				
				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>
			
			<x:template match="prize" mode="PrizeValue">
				<x:text>|</x:text>
				<x:call-template name="Utils.ApplyConversionByLocale">
					<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
					<x:with-param name="code" select="/output/denom/currencycode" />
					<x:with-param name="locale" select="//translation/@language" />
				</x:call-template>
			</x:template>
			
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
