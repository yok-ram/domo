<%
'*******************************************************************
'** PAGE NAME:\Apps\VirtusReport\MIS_Reports\CashFlowPaymentMonthly\CashFlowPaymentMonthly.asp
'** VERSION: 6.0.0.0
'** PURPOSE:
'** NOTES:
'** CREATED:
'** MODIFICATION LOG
'** 1. DATE:		AUTHOR:		DESCRIPTION:
'** 2. DATE:		AUTHOR:		DESCRIPTION:
'*******************************************************************
%>

<!--#INCLUDE VIRTUAL="/System/default.asp"-->
<!--#INCLUDE VIRTUAL="/System/CommonFunctions.asp"-->
<!--#INCLUDE VIRTUAL="/System/DisplayRecordsets.asp"-->
<%


run_search = False
def_check = Request("def_check")

'request the values from the calling page

run_search = Request("run_search")

'Get values for search form
period_code = Trim(Request("period_code"))

'If (period_code = "") Then
'    period_code = "TD"
'End If

start_date = Trim(Request("start_date"))
end_date = Trim(Request("end_date"))
entity_list = Trim(Request("entity_list"))
director_list = Trim(Request("director_list"))
report_type = Trim(Request("report_type"))
status = Trim(Request("status"))
time_range = Trim(Request("time_range"))
deal_type = Trim(Request("deal_type"))


if def_check = "" then
    terminated_deals = 1
    exclude_test_deals = 1
    exclude_mid_office_deals = 1
else
    terminated_deals = request("terminated_deals")
    exclude_test_deals = request("exclude_test_deals")
    exclude_mid_office_deals = request("exclude_mid_office_deals")
end if


If (start_date <> "") And (end_date <> "") Then
	If (IsDate(start_date)) And (IsDate(end_date)) Then
		If (CDate(start_date) > CDate(end_date)) Then
			sErrorMessage = "Start Date cannot be after End Date. Please adjust the appropriate date(s) and try again."
		End If
	Else
		sErrorMessage = "Invalid Date"
	End If
End If


If start_date = "" Then
    start_date = "1/1/2008"
End If
If end_date = "" Then
    end_date = date()
End If

'SQL:Date_Periods
sSQLCmd = "EXEC dbo.Date_Periods @entity_id=" & NumericToSQL(entity_id) & ",@utc_offset=" & numerictosql(sys_clientUTCOffset)
Set rsDatePeriods = GetRS(sSQLCmd)

iDatePeriodCount = -1
Do Until (rsDatePeriods.EOF)
    iDatePeriodCount = iDatePeriodCount + 1
	rsDatePeriods.MoveNext
Loop
%>
<html>
<head>
	<title><%=sys_PageTitle%></title>
	<link rel="stylesheet" href="/StyleSheets/template.CSS" type="text/css">
</head>

<body>
<!--#INCLUDE VIRTUAL="/top.asp"-->

<!-- ********** Begin search fields ********** -->
<form method="post" action="CashFlowPaymentMonthly.asp" id="frmCashFlowSearch" name="frmCashFlowSearch">
	<input type="hidden" name="parm" value="<%=parm%>">
	<input type="hidden" name="run_search" value="True">	<!-- flag to run search -->

	<table border="0" cellspacing="0" class="normal">
	<%

 		sSQLCmd = "EXEC Date_Periods @entity_id=" & NumericToSQL(entity_id)
 		DropDownControl_SQLcmd_Row "period_code","Date Period" ,period_code,sSQLCmd,"period_code","period_description","",False,"",False," onchange='SetDateRange()' "
	%>
	<tr>
		<th class="normal" align="left">
			Start/End Date
		</th>
		<td class="normal" align="left" valign="bottom">
			<% 	TextBoxControl_Object "start_date","Start Date",start_date,"DATE",False,"",False,""	%>
			&nbsp;/&nbsp;
			<%  TextBoxControl_Object "end_date","End Date",end_date,"DATE",False,"",False,"" %>
		</td>
	</tr>
<%
		CheckBoxControl_Row "terminated_deals","Exclude Terminated Deals",terminated_deals ,false," onclick='RefreshForm()' "
		CheckBoxControl_Row "exclude_test_deals","Exclude Test Deals",exclude_test_deals,false," onclick='RefreshForm()' "
		CheckBoxControl_Row "exclude_mid_office_deals","Exclude Middle Office Services Deals",exclude_mid_office_deals,false," onclick='RefreshForm()' "

'		DropDownControl_CodeTable_Row "cash_trans_type", "Payment Type",cash_trans_type, "CASH_PAYMENT_TYPE","Disbursements and Receipts",False,"",False,""

		Set FormObj = New DropDownControl
		FormObj.sControlName = "report_type"
		FormObj.sControlDescription = "Report Type"
		FormObj.Value = report_type
		FormObj.bDataRequired = True
		FormObj.ComponentAttributes = ""
		FormObj.sSelectOption = ""
		FormObj.CustomOptions="CF;Cash Flow|MR;Monthly Report|PR;Payment Report|WK;Weekly Report"
		FormObj.bUseInAutoUpdate = False
		AddControl_Row FormObj
		Set FormObj = Nothing

		Set FormObj = New DropDownControl
		FormObj.sControlName = "status"
		FormObj.sControlDescription = "Status"
		FormObj.Value = status
		FormObj.bDataRequired = True
		FormObj.ComponentAttributes = ""
		FormObj.sSelectOption = ""
		FormObj.CustomOptions="A;All|O;On or Before Due Time|P;Past Due"
		FormObj.bUseInAutoUpdate = False
		AddControl_Row FormObj
		Set FormObj = Nothing

		Set FormObj = New DropDownControl
		FormObj.sControlName = "time_range"
		FormObj.sControlDescription = "Time Range"
		FormObj.Value = time_range
		FormObj.bDataRequired = True
		FormObj.ComponentAttributes = ""
		FormObj.sSelectOption = ""
		FormObj.CustomOptions="A;All|B;Cashflow Due Time|C;On or Before 2:30pm"
		FormObj.bUseInAutoUpdate = False
		AddControl_Row FormObj
		Set FormObj = Nothing
		
		
		sSQLCmd = "EXEC dbo.VRTS_DDA_Director_list @user_id=" & TextToSQL(user_id) & _
		                                      ", @terminated_deals=" & Numerictosql(terminated_deals) & _
		                                      ", @exclude_test_deals=" & Numerictosql(exclude_test_deals) & _
		                                      ", @exclude_mid_office_deals=" & Numerictosql(exclude_mid_office_deals) & _
		                                      ", @end_date = " & DateToSQL(end_date)

		Set FormObj = New SelectListControl
		FormObj.bDataRequired = False
		FormObj.ComponentAttributes = "onchange='RefreshForm()'"
		FormObj.sControlName = "director_list"
		FormObj.sControlDescription = "Director Filter Box"
		FormObj.Value = director_list
		FormObj.SQLCmd = sSQLCmd
		FormObj.SQLValueField = "agent_name"
		FormObj.SQLDisplayField = "agent_name"
		FormObj.ValueDivider = ";"  ' default value: ","
		AddControl_Row FormObj
		
		
		sSQLCmd = "EXEC dbo.VRTS_DDA_Entity_list @user_id=" & TextToSQL(user_id) & _
		                                      ", @terminated_deals=" & Numerictosql(terminated_deals) & _
		                                      ", @exclude_test_deals=" & Numerictosql(exclude_test_deals) & _
		                                      ", @exclude_mid_office_deals=" & Numerictosql(exclude_mid_office_deals) & _
		                                      ", @end_date = " & DateToSQL(end_date) &_
											  ", @director_list=" & TextToSQL(director_list)

		Set FormObj = New SelectListControl
		FormObj.bDataRequired = False
		FormObj.ComponentAttributes = ""
		FormObj.sControlName = "entity_list"
		FormObj.sControlDescription = "Deals to Include"
		FormObj.Value = entity_list
		FormObj.SQLCmd = sSQLCmd
		FormObj.SQLValueField = "entity_id"
		FormObj.SQLDisplayField = "Deal Nickname"
		FormObj.ValueDivider = ";"  ' default value: ","
		AddControl_Row FormObj


		sSQLCmd = "cdosys_Lookup_Code_list 30"
		Set FormObj = New SelectListControl
		FormObj.sControlName="deal_type"
		FormObj.sControlDescription="Deal Type"
		FormObj.Value=deal_type
		FormObj.ValueDivider = ";"
		FormObj.SQLCmd = sSQLCmd
		FormObj.SQLValueField = "code"
		FormObj.SQLDisplayField = "description"
		FormObj.DefaultSelectAll = False
		FormObj.bDataRequired = False
		AddControl_Row FormObj
		Set FormObj = nothing

        HiddenControl_Row "def_check",def_check,""

		Set FormObj = New ExecuteButtonControl
		FormObj.Execute


%>
	</table>
</form>
<button onclick="javascript:SaveToExcel()" id="button2" name="button2">Save To Excel</button>

<!-- ********** End search fields ********** -->
<br><br><br>

<p><span class="SystemMsgText"><%=sErrorMessage%></span></p>
<% If run_search <> "" And sErrorMessage = "" Then %>
	<!--#INCLUDE VIRTUAL="/Includes/ProcessingMsgShow.asp"-->
<%
	sSQLCmd = "EXEC VRTS_Rpt_Cash_Flow_Payment_Monthly " _
		& "@begin_date=" & DateToSQL(start_date) _
		& ", @entity_list=" & TextToSQL(entity_list) _
		& ", @end_date=" & DateToSQL(end_date) _
		& ", @report_type=" & TextToSQL(report_type) _
		& ", @user_id=" & TextToSQL(user_id) _
		& ", @status=" & TextToSQL(status) _
		& ", @time_range=" & TextToSQL(time_range) _
		& ", @deal_type=" & TextToSQL(deal_type) _
		& ", @recordset_number=1"

	Set rsReportResults = GetRS(sSQLCmd)

	sSQLCmd2 = "EXEC VRTS_Rpt_Cash_Flow_Payment_Monthly " _
		& "@begin_date=" & DateToSQL(start_date) _
		& ", @entity_list=" & TextToSQL(entity_list) _
		& ", @end_date=" & DateToSQL(end_date) _
		& ", @report_type=" & TextToSQL(report_type) _
		& ", @user_id=" & TextToSQL(user_id) _
		& ", @status=" & TextToSQL(status) _
		& ", @time_range=" & TextToSQL(time_range) _
		& ", @deal_type=" & TextToSQL(deal_type) _
		& ", @recordset_number=2"


	Set rsReportResults2 = GetRS(sSQLCmd2)

	sSQLCmd3 = "EXEC VRTS_Rpt_Cash_Flow_Payment_Monthly " _
		& "@begin_date=" & DateToSQL(start_date) _
		& ", @entity_list=" & TextToSQL(entity_list) _
		& ", @end_date=" & DateToSQL(end_date) _
		& ", @report_type=" & TextToSQL(report_type) _
		& ", @user_id=" & TextToSQL(user_id) _
		& ", @status=" & TextToSQL(status) _
		& ", @time_range=" & TextToSQL(time_range) _
		& ", @deal_type=" & TextToSQL(deal_type) _
		& ", @recordset_number=3"


	Set rsReportResults3 = GetRS(sSQLCmd3)

	If Not (rsReportResults.EOF And rsReportResults.BOF) Then
		SaveToExcelCommand = sSQLCmd

		ShowListRSbtn _
    				rsReportResults,  _
    				"", _
    				"", _
    				"", _
    				"normal", _
    				"", _
    				"", _
    				"", _
    				""

%>
<br><br>
<h4>Exceptions</h4>
<%

'response.Write sSQLCmd3
		ShowListRSbtn _
    				rsReportResults3,  _
    				"", _
    				"", _
    				"", _
    				"normal", _
    				"", _
    				"", _
    				"", _
    				""


       ' if report_type <> "CF" then
		    'ShowListRSbtn _
    				   ' rsReportResults2,  _
    				   ' "", _
    				   ' "", _
    				   ' "", _
    				   ' "normal", _
    				  '  "", _
    				  '  "", _
    				  '  "", _
    				  '  ""
    	'end if
	Else
		Response.Write "No transactions found."
	End If

	Set rsTransList = Nothing
%>
	<!--#INCLUDE VIRTUAL="/Includes/ProcessingMsgHide.asp"-->
<% End If %>
<br><br>

</body>
</html>

<!--#INCLUDE VIRTUAL="/System/VBSClientSideLib.asp"-->

<script language="vbscript">

	Dim user_id
	user_id = "<%= user_id %>"
	Dim aPeriodBeginDates(<%=iDatePeriodCount%>), aPeriodEndDates(<%=iDatePeriodCount%>)

    Sub RefreshForms()
        <%run_search = False %>
        document.forms("frmCashFlowSearch").submit()
    End Sub

	'This is used to validate/submit the form.
	Sub SubmitForm()
		Dim bReturnValue

		bReturnValue = True
		bReturnValue = ValidateFormControls(document.forms("frmCashFlowSearch"), bReturnValue)

        RemoveFrameworkSystemFieldsValues

		If (bReturnValue) Then
			document.forms("frmCashFlowSearch").submit()
		End If
	End Sub

	'This function sets the date range for the Date Period selected.
	Function SetDateRange()

	       document.all.start_date.value = aPeriodBeginDates(document.all.period_code.selectedIndex)
		   document.all.end_date.value = aPeriodEndDates(document.all.period_code.selectedIndex)
	End Function

	<%
	If Not (rsDatePeriods.EOF And rsDatePeriods.BOF) Then
		rsDatePeriods.MoveFirst
	End If
	iCurrentIndex = -1
	Do Until (rsDatePeriods.EOF)
		iCurrentIndex = iCurrentIndex + 1
	    if isdate(rsDatePeriods("begin_date")) and isdate(rsDatePeriods("end_date")) then
	    %>
	    aPeriodBeginDates(<%=iCurrentIndex%>) = "<%=FormatDateTime(rsDatePeriods("begin_date"),2)%>"
	    aPeriodEndDates(<%=iCurrentIndex%>) = "<%=FormatDateTime(rsDatePeriods("end_date"),2)%>"
	    <%
        else
        %>
        aPeriodBeginDates(<%=iCurrentIndex%>) = ""
        aPeriodEndDates(<%=iCurrentIndex%>) = ""
        <%
	    end if
		rsDatePeriods.MoveNext
	Loop
	%>

	<%
	If (iDatePeriodCount >= 0) And (start_date = "") And (end_date = "") Then
	%>
	SetDateRange()
	<%
	End If
	%>


</script>
<script language="JavaSCRIPT" src="/system/JavaLib.js"></script>
<script language="JavaSCRIPT">

	function showDetails(entity_id, begin_date, end_date){
		cash_trans_type = '<%=cash_trans_type%>';
		payment_status = '<%=payment_status%>';

		OpenWindow("CashStatusAgingByDealDetail.asp?entity_list=" + entity_id + "&start_date=" + begin_date + "&end_date=" + end_date + "&cash_trans_type=" + cash_trans_type + "&payment_status=" + payment_status + "&parm=" + entity_id ,"",800,1000);
	}

	function RefreshForm(){

        period_code = document.all.period_code.value;
        start_date = document.all.start_date.value;
        end_date = document.all.end_date.value;
        terminated_deals = (document.all.terminated_deals.checked) ? 1 : 0
        exclude_test_deals = (document.all.exclude_test_deals.checked) ? 1 : 0
        exclude_mid_office_deals = (document.all.exclude_mid_office_deals.checked) ? 1 : 0
		report_type = document.all.report_type.value;
		status = document.all.status.value;
		time_range = document.all.time_range.value;
		deal_type = document.all.deal_type.value;
        entity_id = '<%=parm%>';
		director_list = document.all.director_list.value;

        url = "CashFlowPaymentMonthly.asp?entity_list=" + entity_id +
                "&start_date=" + start_date +
                "&end_date=" + end_date +
                "&report_type=" + report_type +
                "&status=" + status +
                "&time_range=" + time_range +
                "&terminated_deals=" + terminated_deals +
                "&exclude_test_deals=" + exclude_test_deals +
                "&exclude_mid_office_deals=" + exclude_mid_office_deals +
                "&period_code=" + period_code +
                "&deal_type=" + deal_type +
                "&parm=" + entity_id +
                "&def_check=False" +
				"&director_list=" + director_list;

        window.open( url ,"_parent");
    }
	

	function SaveToExcel(){

        period_code = document.all.period_code.value;
        start_date = document.all.start_date.value;
        end_date = document.all.end_date.value;
        terminated_deals = (document.all.terminated_deals.checked) ? 1 : 0
        exclude_test_deals = (document.all.exclude_test_deals.checked) ? 1 : 0
        exclude_mid_office_deals = (document.all.exclude_mid_office_deals.checked) ? 1 : 0
		report_type = document.all.report_type.value;
		statuss = document.all.status.value;
		time_range = document.all.time_range.value;
		deal_type = document.all.deal_type.value;
        entity_id = '<%=parm%>';
		entity_list = document.all.entity_list.value;
		director_list = document.all.director_list.value;

        url =   "Download.asp?parm=" + entity_id +
                "&start_date=" + start_date +
                "&end_date=" + end_date +
                "&report_type=" + report_type +
                "&status=" + statuss +
                "&time_range=" + time_range +
                "&entity_list=" + entity_list +
				"&director_list=" + director_list;

	    sWindowOptions = "height=600,width=800,status=yes,toolbar=no,menubar=no,location=no,scrollbars=yes,resizable=yes,top=1,left=1";
//	    sWindowOptions = "height=600,width=800,status=yes,toolbar=no,menubar=no,location=no,scrollbars=yes,resizable=yes,top=" & CStr(nTop) & ",left=" & CStr(nLeft)


        window.open( url, "",sWindowOptions);

    }
</script>
<%
Set rsDatePeriods = Nothing
%>
<!--#INCLUDE VIRTUAL="/System/PageFooter.asp"-->
