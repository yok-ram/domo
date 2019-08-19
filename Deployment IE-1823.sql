use [cdo_suite_6]
go

alter table [dbo].[NEX_Snapshot_Classification]
add past_due_reason varchar(500)

go

alter table [dbo].[NEX_Snapshot_Classification]
add past_due_comment varchar(500)

go

alter table [dbo].[NEX_Snapshot_Classification]
add draft_versions_sent_to_client int

go

alter table [dbo].[NEX_Snapshot_Classification]
add date_first_draft_sent_to_client datetime

go

use [cdo_suite_6]
go

alter table [dbo].[VRTS_TPS_Portfolio_Snapshot_Classification]
add past_due_reason varchar(500)

go

alter table [dbo].[VRTS_TPS_Portfolio_Snapshot_Classification]
add past_due_comment varchar(500)

go

alter table [dbo].[VRTS_TPS_Portfolio_Snapshot_Classification]
add draft_versions_sent_to_client int

go

alter table [dbo].[VRTS_TPS_Portfolio_Snapshot_Classification]
add date_first_draft_sent_to_client datetime

go

use [cdo_suite_6]
go

EXEC dbo.cdosys_Lookup_Type_put @lookup_type_id = 0 ,@lookup_type = 'PS_PAST_DUE_REASON' ,@lookup_type_desc = 'Portfolio Snapshot Past Due Reason' ,@USER_ID = 'yram'

declare @lookup_type_id int

select @lookup_type_id = lookup_type_id
from cdosys_Lookup_Type
where lookup_type = 'PS_PAST_DUE_REASON'

EXEC dbo.cdosys_Lookup_Code_put @lookup_type_id = @lookup_type_id ,@lookup_code_id = 0 ,@lookup_code = 'Client' ,@lookup_code_desc = 'Client' ,@display_order = 1 ,@USER_ID = 'yram'
EXEC dbo.cdosys_Lookup_Code_put @lookup_type_id = @lookup_type_id ,@lookup_code_id = 0 ,@lookup_code = 'Client Services' ,@lookup_code_desc = 'Client Services' ,@display_order = 1 ,@USER_ID = 'yram'
EXEC dbo.cdosys_Lookup_Code_put @lookup_type_id = @lookup_type_id ,@lookup_code_id = 0 ,@lookup_code = 'Analytics' ,@lookup_code_desc = 'Analytics' ,@display_order = 1 ,@USER_ID = 'yram'
EXEC dbo.cdosys_Lookup_Code_put @lookup_type_id = @lookup_type_id ,@lookup_code_id = 0 ,@lookup_code = 'GAA' ,@lookup_code_desc = 'GAA' ,@display_order = 1 ,@USER_ID = 'yram'
EXEC dbo.cdosys_Lookup_Code_put @lookup_type_id = @lookup_type_id ,@lookup_code_id = 0 ,@lookup_code = 'IT' ,@lookup_code_desc = 'IT' ,@display_order = 1 ,@USER_ID = 'yram'
EXEC dbo.cdosys_Lookup_Code_put @lookup_type_id = @lookup_type_id ,@lookup_code_id = 0 ,@lookup_code = 'Settlements' ,@lookup_code_desc = 'Settlements' ,@display_order = 1 ,@USER_ID = 'yram'

go

USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[NEX_Snapshot_classification_get]    Script Date: 6/13/2019 2:38:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

USE [cdo_suite_6]
GO
/****** Object:  UserDefinedFunction [dbo].[VRTS_TPS_getSnapshotClassification]    Script Date: 7/17/2019 2:47:32 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE FUNCTION [dbo].[VRTS_TPS_getSnapshotClassification]

/*******************************************************************
* PURPOSE: Get the snapshot classification for TRS
* NOTES: IE-1868	Duco pull	07/17/2019
* AUTHOR:	Yokesh Ram
* MODIFIED 
* DATE		AUTHOR			DESCRIPTION
*-------------------------------------------------------------------
*******************************************************************/

(@tps_id int, 
 @request_type varchar(10))

RETURNS varchar(60)

AS  

BEGIN 
Declare @desc varchar(50)

	IF (@request_type = 'code') BEGIN

		Select @desc=classification_code from VRTS_TPS_Portfolio_Snapshot_Classification
		where tps_id = @tps_id
	END ELSE IF (@request_type = 'desc') BEGIN
	
		Select 
			@desc=dbo.NEX_lookupCodeDesc('SNAPSHOT_CLASSIFICATION', classification_code)
		from VRTS_TPS_Portfolio_Snapshot_Classification
		where tps_id = @tps_id

	--END ELSE IF (@request_type = 'report') BEGIN
		
	--	Select 
	--		@desc=report_display_type
	--	from nex_snapshot_classification_desc
	--	where classification_code = (Select classification_code from nex_snapshot_classification
	--					where ps_id = @ps_id)
	END

	RETURN @desc
END


GO


ALTER PROCEDURE [dbo].[NEX_Snapshot_classification_get]

/*******************************************************************
* PROCEDURE: 
* PURPOSE: 
* NOTES: 
* CREATED:
* MODIFIED 
* DATE			AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
* 05/31/2019	YR			IE-1823	NEX_Snapshot_classification will contain more columns 
* 06/13/2019	YR			IE-1835	NEX_Snapshot_classification will contain last_update_date
*******************************************************************/

	@ps_id int

AS

BEGIN

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

	declare @entity_id int
	declare @as_of_date datetime
	declare @mr_due_date datetime
	declare @pr_due_date datetime

	select @entity_id = entity_id,
		@as_of_date = as_of_date
	from PS_portfolio_snapshot
	where ps_id = @ps_id

	select @mr_due_date = due_date
	from vrts_deal_report_schedule
	where entity_id = @entity_id
		and report_date = @as_of_date

	select @pr_due_date = ndps.due_date
	from Deal_Payment_Schedule dps
	left join dbo.NEX_Deal_Payment_Schedule_extended ndps ON dps.deal_payment_id = ndps.deal_payment_id
	where entity_id = @entity_id
		and determination_date = @as_of_date

	SELECT
		ltrim(rtrim(classification_code)) as 'classification_code',
		row_version = CAST(row_version AS bigint),
		past_due_reason,	-- IE-1823
		past_due_comment,	-- IE-1823
		draft_versions_sent_to_client,	-- IE-1823
		date_first_draft_sent_to_client,	-- IE-1823
		@entity_id as 'entity_id',	-- IE-1823
		@as_of_date as 'as_of_date',	-- IE-1823
		isnull(@mr_due_date, '1/1/1900') as 'mr_due_date',	-- IE-1823
		isnull(@pr_due_date, '1/1/1900') as 'pr_due_date',	-- IE-1823
		last_update_date as 'last_update_date'				-- IE-1835
	FROM NEX_Snapshot_classification
	WHERE ps_id = @ps_id


SET NOCOUNT OFF
SET ANSI_WARNINGS ON

END

go

USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[NEX_Snapshot_classification_put]    Script Date: 5/28/2019 11:16:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  PROCEDURE [dbo].[NEX_Snapshot_classification_put]
/*******************************************************************
* PROCEDURE: 
* PURPOSE: Adds or updates the snapshot classification
* NOTES: 
* CREATED: 
* MODIFIED 
* DATE		AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
* 01/28/08	MMR			Change @classification_code char(2) to
							   @classification_code char(4).
						Tables NEX_Snapshot_Classification & NEX_Snapshot_Classification_Desc
						also modified classification_code to char(4) to allow for INT and 1IT
						in Interim Reports.
* 12/10/2012 AST		<CDOSBAU-2646> Prevent users from approving two snapshots with same as_of_date, classification_code
* 01/29/2014 RSO		<CDOSBAU-3421> Added validation to prevent snapshot approved without all tests being run
* 04/21/2014 SRD		<CDOSBAU-4494> Suppress sifma file generation for compliance and interim snapshots
* 08/18/2014 SRD		<CDOSBAU-5305> add @upload_to_nexus parameter to suppress init/pre-trade snapshots manually approved from uploading
						fixed bug where entity_id was hardcoded  for pre-trade comparison upload
* 11/7/2016	 IO			Added filter to exclude Excel full report on Madison Park X Ltd  --CDOSBAU-11601
* 10/11/2017 TLe		Moddified to use the include_excel_version flag --(IE-428 IE-936 IE-937)
* 06/05/2019 YR			IE-1823	NEX_Snapshot_classification will contain more columns 
*******************************************************************/
@user_id				user_id,
@row_version			bigint, 
@ps_id					int,
@classification_code	char(4),
@operation_confirmed	tinyint		= 0,
@upload_to_nexus		bit			= 1,
@past_due_reason		varchar(500) = null,
@past_due_comment		varchar(500) = null,
@draft_versions_sent_to_client int = null,
@date_first_draft_sent_to_client datetime = null,
@entity_id				int = null,
@as_of_date				datetime = null,
@mr_due_date			datetime = null,
@pr_due_date			datetime = null
AS

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @operation_result_code int,
	@operation_message_code varchar(50),
	@action_message_code varchar(50),
	@operation_details varchar(1000),
	@record_exists tinyint,
	@doc_parameters_shared varchar(2000),
	@exists bit,
	@doc_type_id int,
	@entity_id_list varchar(50),
	@description varchar(255),
	@parms varchar(255),
	@record_id int,
	@temp_location varchar(255),
	@package_id int,
	@all_tests_have_run bit,
	@abort_updates bit

SET @exists = 0
SET @abort_updates = 0

DECLARE @documents TABLE (record_id int identity(1,1), as_of_date datetime, entity_id int, description varchar(255), doc_type_id int, doc_parameters varchar(255),temp_location varchar(255))

SELECT @entity_id=entity_id, @as_of_date=as_of_date
FROM dbo.PS_Portfolio_Snapshot
WHERE ps_id = @ps_id

SET @operation_result_code = @@ERROR
SET @record_exists = CASE
			WHEN EXISTS (SELECT TOP 1 * FROM NEX_Snapshot_Classification
				WHERE ps_id = @ps_id)				
			THEN 1 ELSE 0 END

/* ABORT UPDATES IF THE CURRENT ROWVERSION IS DIFFERENT THAN THE RETRIEVED ROWVERSION*/
IF @record_exists = 1 AND @operation_confirmed = 0
  BEGIN
	DECLARE @conflicting_row_version bigint,
		@conflicting_user_data varchar(1000)

	SELECT
		@conflicting_row_version = CAST(row_version AS bigint),
		@conflicting_user_data = 'Last Updated by ' + dbo.UserName(last_updated_by) + ' on '  + CONVERT(varchar,last_update_date)
	FROM NEX_Snapshot_Classification
	WHERE ps_id = @ps_id	

	IF ISNULL(@row_version,0) = 0
		SELECT
			@operation_result_code = operation_result_code,
			@operation_message_code = operation_message_code,
			@action_message_code = action_message_code,
			@operation_details = @conflicting_user_data
		FROM tf_ActionMessage ('NEW_RECORD_MODIFIES_EXISTING_ONE')
	ELSE IF @row_version <> @conflicting_row_version
		SELECT
			@operation_result_code = operation_result_code,
			@operation_message_code = operation_message_code,
			@action_message_code = action_message_code,
			@operation_details = @conflicting_user_data
		FROM tf_ActionMessage ('ROWVERSION_CONFLICT')

	-- <CDOSBAU-2646> 
	-- AST 12-7-2012 
	-- Prevent users from approving two snapshots with same entity, as_of_date, classification_code.
	-- Always allow 'Not Approved'.
	IF @classification_code <> 'NA' BEGIN
		DECLARE @classification_exists bit
		SET @classification_exists = CASE WHEN EXISTS(
			SELECT TOP 1 *
			FROM dbo.PS_Portfolio_Snapshot snap
			 JOIN NEX_Snapshot_Classification sc ON snap.ps_id = sc.ps_id
			WHERE snap.entity_id = @entity_id 
				and snap.as_of_date=@as_of_date 
				and sc.classification_code = @classification_code)
			THEN 1 ELSE 0 END
		--- SET RESULT CODE OR WHATEVER TO FAIL THE OPERATION
		IF @classification_exists = 1
			SELECT
				@operation_result_code = operation_result_code,
				@operation_message_code = operation_message_code,
				@action_message_code = action_message_code,
				@operation_details = ''
			FROM tf_ActionMessage ('CC_EXISTS')
			
			
		SELECT @package_id = package_id FROM vrts_rpt_package WHERE entity_id = @entity_id and default_package = 1		

		CREATE TABLE #PS_Verify_Test (record_id int identity(1,1), all_tests_have_run bit)
		
		INSERT #PS_Verify_Test (all_tests_have_run)
		EXEC dbo.VRTS_PS_Verify_Test_Execution @ps_id = @ps_id, @package_id = @package_id

		SELECT TOP 1 @all_tests_have_run = ISNULL(all_tests_have_run,0) FROM #PS_Verify_Test
		
		/* ABORT UPDATES IF One or more tests have not been run for the snapshot.*/	
		IF @all_tests_have_run = 0
		  BEGIN
			SELECT
				@operation_result_code = operation_result_code,
				@operation_message_code = operation_message_code,
				@action_message_code = action_message_code,
				@operation_details = '',
				@abort_updates = 1
			FROM tf_ActionMessage ('PS_TESTS_NOT_COMPLETED')
		  END	
	END --IF @classification_code <> 'NA'

	--</CDOSBAU-2646>

  END

IF @abort_updates = 0
	BEGIN
		IF (@operation_confirmed = 1 AND @operation_result_code < 30)
		OR (@operation_confirmed = 0 AND @operation_result_code < 10)
		  BEGIN
			IF @record_exists = 0
			  BEGIN
				INSERT NEX_Snapshot_Classification (
					ps_id,
					classification_code,			
					created_by,
					create_date,
					last_updated_by,
					last_update_date,
					past_due_reason,	-- IE-1823
					past_due_comment,	-- IE-1823
					draft_versions_sent_to_client,	-- IE-1823
					date_first_draft_sent_to_client)	-- IE-1823
				VALUES (
					@ps_id,
					@classification_code,
					@user_id,
					CURRENT_TIMESTAMP,
					@user_id,
					CURRENT_TIMESTAMP,
					@past_due_reason,	-- IE-1823
					@past_due_comment,	-- IE-1823
					@draft_versions_sent_to_client,	-- IE-1823
					@date_first_draft_sent_to_client)	-- IE-1823

				SET @operation_result_code = @@ERROR
			  END
			ELSE
			  BEGIN
				UPDATE NEX_Snapshot_Classification
				SET
					classification_code = @classification_code,			
					last_updated_by = @user_id,
					last_update_date = CURRENT_TIMESTAMP,
					past_due_reason = @past_due_reason,	-- IE-1823
					past_due_comment = @past_due_comment,	-- IE-1823
					draft_versions_sent_to_client = @draft_versions_sent_to_client,	-- IE-1823
					date_first_draft_sent_to_client = @date_first_draft_sent_to_client	-- IE-1823
				WHERE ps_id = @ps_id

				SET @operation_result_code = @@ERROR
			  END
		  END

		  SET @doc_parameters_shared = 'ps_id;' + convert(varchar(24), @ps_id) + '%'

		  IF (@classification_code = 'NA') BEGIN
			update ps_portfolio_snapshot set read_only = 0 where ps_id = @ps_id

			
			IF  dbo.nex_getDealSetting(@entity_id, 'conceal_names') = 1 BEGIN
				EXEC NEX_PS_Mask_Names @ps_id, 'RESTORE'
			END	
			
			UPDATE aspnetdb.dbo.document set status = 'DELETED', upload_confirmed = 0, force_retry = 1, date_updated = current_timestamp, user_updated = @user_id where doc_parameters like @doc_parameters_shared
			
			-- if this is an inital snapshot with a corresponding pre-trade snapshot, delete the pre-trade vs init report too
			declare @ps_id_pre_trade int = ( SELECT top 1 tr.ps_id_1 from virtustrade..PS_TR_Overall_Summary tr where tr.ps_id_2 = @ps_id order by tr.PS_TR_Overall_Summary_id desc)
			IF @ps_id_pre_trade is not null 
			BEGIN
				SET @doc_parameters_shared = 'ps_id;' + convert(varchar(24), @ps_id_pre_trade) + '%'
				UPDATE aspnetdb.dbo.document set status = 'DELETING', upload_confirmed = 0, force_retry = 1, date_updated = current_timestamp, user_updated = @user_id where doc_parameters like @doc_parameters_shared
			END
			
		  END ELSE BEGIN
			update ps_portfolio_snapshot set read_only = 1 where ps_id = @ps_id

			
			IF  dbo.nex_getDealSetting(@entity_id, 'conceal_names') = 1 BEGIN
				EXEC NEX_PS_Mask_Names @ps_id, 'MASK'
			END
			
			SELECT TOP 1
				@exists = 1
			FROM
				aspnetdb.dbo.document
			WHERE
				doc_parameters  like @doc_parameters_shared

			
			IF @exists = 1 BEGIN			
				DELETE aspnetdb.dbo.document  where doc_parameters like @doc_parameters_shared
			END 

			IF @upload_to_nexus = 1
			BEGIN
				insert @documents
					SELECT 
							as_of_date = as_of_date,
							entity_id = ps.entity_id,
							description = convert(varchar(10), as_of_date, 101) + ' - ' +  report_display_type,
							doc_type_id = doc_type_id,
							parms = 'ps_id;' + convert(varchar(15), ps_id) + ':package_id;' + convert(varchar(15), package_id),
							temp_location = NULL		
						FROM 
							cdo_suite_6.dbo.PS_Portfolio_Snapshot ps JOIN  cdo_suite_6.dbo.nex_snapshot_classification_desc cd on
								cdo_suite_6.dbo.nex_getSnapshotClassification(ps.ps_id, 'CODE') = cd.classification_code join
								aspnetdb.dbo.document_type dt on cd.classification_code = dt.doc_type join vrts_rpt_package rp
							on ps.entity_id = rp.entity_id
					WHERE
						ps_id = @ps_id
						AND include_in_nexus = 1
						AND  suffix != 'xml'
						AND  ( file_name != 'SIFMA' OR ( file_name = 'SIFMA' AND include_sifma = 1  AND cdo_suite_6.dbo.nex_getSnapshotClassification(ps.ps_id, 'CODE') NOT IN('DIN', 'DPT', 'INT')) ) 
						--AND NOT ((ps.entity_id = 538) AND (doc_type_id = 71) and (package_id = 356))  -- <IO 11/7/2016 CDOSBAU-11601>
						AND suffix <> CASE WHEN rp.include_excel_version = 0 THEN 'xls'  ELSE '' END --IE-428 IE-936 IE-937

				SELECT @record_id = min(record_id) from @documents

				WHILE @record_id is not null BEGIN
					SELECT 
						@as_of_date = as_of_date,
						@entity_id_list = convert(varchar(25),entity_id),
						@description = description,
						@doc_type_id = doc_type_id,
						@parms = doc_parameters,
						@temp_location = temp_location
					FROM 
						@documents
					WHERE
						record_id = @record_id
				
					EXEC aspnetdb.dbo.nex_document_put @entity_id_list = @entity_id_list, @doc_name = @description, @user_id = @user_id, @doc_id = 0, @doc_type_id = @doc_type_id, @doc_parameters = @parms, @as_of_date = @as_of_date, @temp_location = @temp_location , @status='PENDING'
					SELECT @record_id = min(record_id) from @documents where record_id > @record_id
				END
				
				IF cdo_suite_6.dbo.nex_getSnapshotClassification(@ps_id, 'CODE') = 'DPT'
				BEGIN
					-- its a pre-trade, post the pre-trade vs init report
					declare 
						@ps_id_init int = ( SELECT top 1 tr.ps_id_2 from virtustrade..PS_TR_Overall_Summary tr where tr.ps_id_1 = @ps_id order by tr.PS_TR_Overall_Summary_id desc)
						,@path varchar(4000) = (SELECT virtusutil.dbo.[fn_decode_parm]('%%VIRTUS_COMM_TEMP_FOLDER%%') + '\ActuateUploadGenerate\PTIC\' + cast(@ps_id as varchar) )
						INSERT INTO aspnetdb.dbo.document(
						[entity_id]
						,[ps_id]
						,[doc_name]
						,[doc_type_id]
						,[doc_parameters]
						,[as_of_date]
						,[temp_location]
						,[upload_confirmed]
						,[status]
						,[date_created]
						,[user_created]
						,[output_file_type]
						,[report_name]
						,[report_format]
						,[report_parameters]
						,output_path
					 )
					 VALUES(
						@entity_id
						,@ps_id
						,'Pre-Trade Initial Comparison Report'
						,( SELECT doc_type_id FROM [aspnetdb].[dbo].[document_type] WHERE doc_type = 'PTRD' )
						,'ps_id;' + cast(@ps_id as varchar)
						,@as_of_date
						,@path + '\PTIC.pdf'
						,0
						,'PENDING'
						,GETDATE()
						,@user_id
						,'ACT'
						,'/Public//StandardCompliance/pre_trade_initial_comparison.rptdesign'
						,'PDF'
						,'ps_id=' + cast(@ps_id as varchar) + '&ps_id2=' + cast(@ps_id_init as varchar) + '&deal_name=' + (SELECT deal_name from cdo_suite_6..entity where entity_id = @entity_id) + '&as_of_date=' + convert (varchar, @as_of_date, 101)
						,@path
					)
				END
			END -- @upload_to_nexus				
		  END 
	END
/* RETURN MESSAGES TO FRONT END */
SELECT
	operation_primary_key = 'snapshot_id;' + CAST(@ps_id AS varchar)
				
				,
	*
FROM tf_OperationMessage (@operation_result_code, @operation_message_code, @action_message_code, @operation_details)

SET NOCOUNT OFF
SET ANSI_WARNINGS ON

go

USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[PS_Portfolio_Snapshot_get]    Script Date: 6/24/2019 3:25:28 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[PS_Portfolio_Snapshot_get] 
/*******************************************************************
* PURPOSE: Retrieves Portfolio Snapshot information for a specific ps_id
* NOTES: 
* CREATED BY: Michael Reisman 1/22/2003
* MODIFIED 
* DATE        AUTHOR        DESCRIPTION
* -------------------------------------------------------------------
*04/05/2005   SR     Added A.S. ID's
*05/10/2005   JJ     Set the logic to hide the Assumtion Scenario field if the snapshot is Imported.
*10/14/2005   WS     Added Assumption Scenario ID to the recordset
*03/23/2006   JS     Added as_id to results.
*04/20/2006   JS     Added new multiple as_id fields to results.
*05/17/2006   JS     Assumption scenario value defaults to None when null.
*07/10/2006   JS     Added ps_purpose.
*08/14/2007   DM     Modified for sub entities and version
*04/07/2008   JS     Added ipr_id and proj_source.
*12/18/2008   JS     Added ps_compl_cash_basis.
*01/09/2009   CC     Replace Assumption by Calculation Sequence, add dcs_id, calc_list, cal_run  --REMOVED FOR 6.4.2.0
*06/07/2010   SC	 Added ps_status bug 1262
*12/20/2017	  SI	 Adding new Parameter cash_date_basis --(APPDEV-3047)
*08/23/2018	  RA	 Added generation status from regeneration queue (STRAT-835)
*06/14/2017	  YR	 IE-1835 added additional columns
*******************************************************************/
(
       @ps_id int
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @ps_type lookup_code;

	-- IE-1835
	declare @past_due_reason varchar(500),
		@past_due_comment varchar(500),
		@approval_date datetime,
		@classification_code varchar(50)

	SELECT @ps_type = ps_type FROM PS_portfolio_snapshot WHERE ps_id = @ps_id

	select @past_due_comment = past_due_comment,
		@past_due_reason = past_due_reason,
		@approval_date = last_update_date,
		@classification_code = ltrim(rtrim(classification_code))
	from NEX_Snapshot_Classification
	where ps_id = @ps_id 

	IF (@ps_type = 'IMP') /* Imported snapshot */
		SELECT 
			field_header_properties = 'Sub-Entity Name;' + ISNULL(e.sub_entity_name, 'Sub-Entity Name') + ';' + CASE WHEN e.has_sub_entities = 1 THEN '0' ELSE '1' END
			+ '|Reference Portfolio;Reference Portfolio;' + CASE WHEN RTRIM(e.system_entity_type) = 'SCDO' THEN '0' ELSE '1' END,
			[PS ID] = ps.ps_id,
			[Sub-Entity Name] = dbo.SubEntityName(ps.sub_entity_id),
			[Reference Portfolio] = crp.rp_description,
			[Description] = ISNULL(ps_description,dbo.PS_DefaultDesc(ps.ps_id)),
			[As of Date] = ps.as_of_date,
			[Date Basis] = dbo.CodeDesc ('DATE_BASIS',ps.date_basis),
			[Cash Date Basis] = dbo.CodeDesc('CASH_DATE_BASIS',ps.cash_date_basis), --(APPDEV-3047)
			[Virtus Snapshot Type] = dbo.CodeDesc('VRTS_PS_TYPE',ps.vrts_ps_type),
			[Compliance Date Basis for Cash] = dbo.CodeDesc ('PS_COMPL_CASH_BASIS',ps.ps_compl_cash_basis),
			[Snapshot Purpose] = dbo.CodeDesc ('PS_PURPOSE', ps.ps_purpose),
			[Snapshot Type] = dbo.CodeDesc ('PS_TYPE',ps.ps_type),
			[Read Only] = ps.read_only,
			[Comments] = ps.comments,
			[Created By] = dbo.UserName(ps.created_by),
			[Date Created] = ps.create_date,
			[Time Created] = CONVERT(varchar,ps.create_date,108),
			[Last Updated By] = dbo.UserName(ps.last_updated_by),
			[Last Updated Date] = ps.last_update_date,
			[Version Used to Generate] = ISNULL(sys_version, 'Prior to 6.3.0.0.0000'),
			[Generation] = CASE WHEN EXISTS(SELECT 1 FROM dbo.VRTS_PS_Regen_Queue WHERE ps_id = @ps_id AND (start_time IS NULL OR ISNULL(status_message, 'Waiting') = 'Waiting')) THEN 'Waiting' ELSE dbo.CodeDesc('PS_STATUS', ISNULL(ps.ps_status, 'FIN')) END,
			ps.ps_id,
			ps.as_id_1,
			ps.as_id_2,
			ps.as_id_3,
			ps.as_id_4,
			ps.entity_id,
			ps.as_of_date,
			ps.date_basis,
			ps.ps_compl_cash_basis,
			ps.ps_purpose,
			cash_balances = dbo.PS_DataValue(@ps_id, 'CASH'),
			ei_balances = dbo.PS_DataValue(@ps_id, 'EI'),
			ps.ps_type,
			ps.filter_expression,
			ps.read_only,
			ps.ps_scope,
			ps.sub_entity_id,
			ps.ipr_id,
			ps.proj_source,
		--Virtus
			ps.vrts_ps_type,
			ps.cash_date_basis, --(APPDEV-3047)
			allow_as_of_date_edit = dbo.ConfigValue('ALLOW_PS_AS_OF_DATE_EDIT', e.entity_id),
		--/Virtus
			-- IE-1835
			@past_due_reason as 'past_due_reason',
			@past_due_comment as 'past_due_comment',
			@approval_date as 'approval_date',
			@classification_code as 'classification_code'
		FROM
			dbo.PS_portfolio_snapshot ps 
			INNER JOIN dbo.Entity e ON ps.entity_id = e.entity_id 
			LEFT OUTER JOIN dbo.CDS_Ref_Portfolio crp ON ps.rp_id = crp.rp_id
		WHERE 
			ps.ps_id = @ps_id;
	ELSE /* not an Imported snapshot */
	   SELECT 
			field_header_properties = 'Sub-Entity Name;' + ISNULL(e.sub_entity_name, 'Sub-Entity Name') + ';' + CASE WHEN e.has_sub_entities = 1 THEN '0' ELSE '1' END
			+ '|Reference Portfolio;Reference Portfolio;' + CASE WHEN RTRIM(e.system_entity_type) = 'SCDO' THEN '0' ELSE '1' END,
			[PS ID] = ps.ps_id,
			[Sub-Entity Name] = dbo.SubEntityName(ps.sub_entity_id),
			[Reference Portfolio] = crp.rp_description,
			[Description] = ISNULL(ps_description,dbo.PS_DefaultDesc(ps.ps_id)),
			[As of Date] = ps.as_of_date,
			[Date Basis] = dbo.CodeDesc ('DATE_BASIS',ps.date_basis),
			[Cash Date Basis] = dbo.CodeDesc('CASH_DATE_BASIS',ps.cash_date_basis), --(APPDEV-3047)
			[Virtus Snapshot Type] = dbo.CodeDesc('VRTS_PS_TYPE',ps.vrts_ps_type),
			[Compliance Date Basis for Cash] = dbo.CodeDesc ('PS_COMPL_CASH_BASIS',ps.ps_compl_cash_basis),
			[Snapshot Purpose] = dbo.CodeDesc ('PS_PURPOSE', ps.ps_purpose),
			[Snapshot Type] = dbo.CodeDesc ('PS_TYPE',ps.ps_type),
			[Projected Payments Data Source] = dbo.CodeDesc('PROJ_SOURCE', ps.proj_source),
			[Assumption Scenario #1] = ISNULL((SELECT as_description FROM AS_Scenario scen WHERE scen.as_id = ps.as_id_1), 'None'),
			[Assumption Scenario #2] = ISNULL((SELECT as_description FROM AS_Scenario scen WHERE scen.as_id = ps.as_id_2), 'None'),
			[Assumption Scenario #3] = ISNULL((SELECT as_description FROM AS_Scenario scen WHERE scen.as_id = ps.as_id_3), 'None'),
			[Assumption Scenario #4] = ISNULL((SELECT as_description FROM AS_Scenario scen WHERE scen.as_id = ps.as_id_4), 'None'),
			[Read Only] = ps.read_only,
			[Comments] = ps.comments,
			[Created By] = dbo.UserName(ps.created_by),
			[Date Created] = ps.create_date,
			[Time Created] = CONVERT(varchar,ps.create_date,108),
			[Last Updated By] = dbo.UserName(ps.last_updated_by),
			[Last Updated Date] = ps.last_update_date,
			[Version Used to Generate] = ISNULL(sys_version, 'Prior to 6.3.0.0.0000'),
			[Generation] = CASE WHEN EXISTS(SELECT 1 FROM dbo.VRTS_PS_Regen_Queue WHERE ps_id = @ps_id AND (start_time IS NULL OR ISNULL(status_message, 'Waiting') = 'Waiting')) THEN 'Waiting' ELSE dbo.CodeDesc('PS_STATUS', ISNULL(ps.ps_status, 'FIN')) END,
			ps.ps_id,
			ps.as_id_1,
			ps.as_id_2,
			ps.as_id_3,
			ps.as_id_4,
			ps.entity_id,
			ps.as_of_date,
			ps.date_basis,
			ps.ps_compl_cash_basis,
			ps.ps_purpose,
			cash_balances = dbo.PS_DataValue(@ps_id, 'CASH'),
			ei_balances = dbo.PS_DataValue(@ps_id, 'EI'),
			ps.ps_type,
			ps.filter_expression,
			ps.read_only,
			ps.ps_scope,
			ps.sub_entity_id,
			ps.ipr_id,
			ps.proj_source,
			--Virtus
			ps.vrts_ps_type,
			ps.cash_date_basis, --(APPDEV-3047)
			allow_as_of_date_edit = dbo.ConfigValue('ALLOW_PS_AS_OF_DATE_EDIT', e.entity_id),
		--/Virtus
		-- IE-1835
			@past_due_reason as 'past_due_reason',
			@past_due_comment as 'past_due_comment',
			@approval_date as 'approval_date',
			@classification_code as 'classification_code'
		FROM
			dbo.PS_portfolio_snapshot ps 
			INNER JOIN dbo.Entity e ON ps.entity_id = e.entity_id 
			LEFT OUTER JOIN dbo.CDS_Ref_Portfolio crp ON ps.rp_id = crp.rp_id
		WHERE
			ps.ps_id = @ps_id;
END

go

USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[PS_put]    Script Date: 6/24/2019 3:53:30 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[PS_put]
/*******************************************************************
* PURPOSE: Adds data to PS_portfolio_snapshot
* NOTES: 
* CREATED: 1/8/2003 by Michael Reisman
* MODIFIED 
* DATE		AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
*07/22/2003	MR	Added standard result set
*07/24/2003	MR	Added read-only stop condition
*03/28/2005	MR 	Assumption Scenarios added
*04/19/2006	JS	Added # to ps_description when blank.
*04/20/2006	JS	Added new multiple as_id parameters.
*07/10/2006	JS	Added @ps_purpose and validation for it.
*07/11/2006	HW	Added Validation logic
*07/11/2006	HW	Added @operation_message_code OUPUT logic
*06/20/2007	JS	Fixed validation for PS_PURPOSE_DUPE.
*08/14/2007 DM	Modified for sub_entities, referene portfolio and ps scope
*08/22/2007	SR	Added version
*04/07/2007	SR	Modified for new projections
*12/18/2008	JS	Added @ps_compl_cash_basis.
*08/03/2009	SC	Added new error handling
*05/22/2010	MMR	6.5.1 Recon
*12/20/2017	SI	Adding new Parameter @cash_date_basis --(APPDEV-3047)
*01/08/2019 BWM IE-1523 Adding Parameter @run_ps_tests, @ps_classification_code
*06/14/2019	YR	IE-1835 adding additional parameters to proc which will not be used but required for the asp page call
*******************************************************************/

	@ps_id int OUTPUT,
	@ps_description varchar(100) = NULL,
	@entity_id int,
	@sub_entity_id int = NULL,
	@rp_id int = NULL,
	@ps_scope lookup_code = 'AP',
	@as_of_date smalldatetime,
	@date_basis lookup_code,
	@ps_purpose lookup_code,
	@ps_type lookup_code,
	@user_id user_id = NULL,
	@read_only tinyint = 0,
	@as_id_1 int = NULL,
	@as_id_2 int = NULL,
	@as_id_3 int = NULL,
	@as_id_4 int = NULL,
	@proj_source lookup_code = 'PS',
	@ps_compl_cash_basis lookup_code = 'PS',
	@comments comments_big = NULL,
	@begin_date smalldatetime = NULL, --Virtus
	@trs_position_type varchar(4) = NULL, --Virtus
	@operation_confirmed tinyint = 0,
	@silent_mode tinyint = 0,
	@vrts_ps_type varchar(4) = NULL,
	@cash_date_basis lookup_code = 'CASH', --Virtus - (APPDEV-3047)
	@run_ps_tests bit = 0,					   -- (IE-1523) 
	@ps_classification_code varchar(4) =NULL,   -- (IE-1523)
	@past_due_reason varchar(500) = null,	-- IE-1835
	@past_due_comment varchar(500) = null,	-- IE-1835
	@approval_date datetime = null,				-- IE-1835
	@classification_code varchar(50) = null		-- IE-1835

AS
BEGIN

	SET NOCOUNT ON;
	BEGIN TRY;

		DECLARE
			@proc_name sysname,
			@tran_count int,
			@message_code varchar(50),
			@operation_details varchar(1000),
			@operation_primary_key varchar(1000),
			@pk_id int;

		SELECT 
			@proc_name = object_name(@@procid),
			@tran_count = @@trancount,
			@pk_id = @ps_id,
			@operation_primary_key = NULL; --set below--
		
	
		IF ISNULL(dbo.ConfigValue('PS_GEN_TRAN', NULL),0) = 1 
		BEGIN
			IF @@trancount = 0
				BEGIN TRAN @proc_name;
			ELSE
				SAVE TRAN @proc_name;
		END

		--Start--
		EXEC dbo.cdosys_Start_Procedure 
			@proc_id = @@procid,
			@user_id = @user_id,
			@silent_mode = @silent_mode,		
			@starting_tran_count = @tran_count,
			@pk_id = @pk_id, 
			@row_version = NULL, 
			@operation_confirmed = @operation_confirmed;


		--There can only be one PS with a purpose of "Reporting" for any given combination of As of Date, Date Basis and Deal.--
		IF	@ps_purpose = 'RE' 
		AND EXISTS
		(
			SELECT ps_id
			FROM 
				dbo.PS_Portfolio_Snapshot 
			WHERE 
				entity_id = @entity_id 
			AND as_of_date = @as_of_date 
			AND date_basis = @date_basis 
			AND ps_purpose = @ps_purpose
			AND ps_id <> @ps_id
		)
			EXEC dbo.cdosys_Return_UI @proc_id = @@procid,  @throw_error = 1,  @message_code = 'PS_PURPOSE_DUPE', @operation_details = NULL;


		IF @ps_description IS NULL
			SELECT @ps_description 
				= CONVERT(varchar,@as_of_date,107)
				+ ' '
				+ dbo.CodeDesc ('PS_TYPE',@ps_type) 
				+ ' #'
				+ CONVERT(varchar(3), (SELECT COUNT(*) + 1 FROM dbo.PS_Portfolio_Snapshot WHERE entity_id = @entity_id AND as_of_date = @as_of_date)) 
				+ ', '
				+ dbo.CodeDesc ('DATE_BASIS',@date_basis);


		IF @ps_id = 0
		BEGIN
			INSERT dbo.PS_Portfolio_Snapshot
				(
				ps_description,
				entity_id,
				sub_entity_id,
				rp_id,
				ps_scope,
				as_of_date,
				date_basis,
				ps_purpose,
				ps_type,
				read_only,
				sys_version,
				as_id_1,
				as_id_2,
				as_id_3,
				as_id_4,
				proj_source,
				ps_compl_cash_basis,
				comments,
				begin_date, --Virtus
				trs_position_type, --Virtus
				created_by,
				create_date,
				last_updated_by,
				last_update_date,
				vrts_ps_type,
				cash_date_basis, --Virtus - (APPDEV-3047)
				run_ps_tests,        -- (IE-1523) 
				ps_classification_code  -- (IE-1523) 
				)
			VALUES
				(
				@ps_description,
				@entity_id,
				@sub_entity_id,
				@rp_id,
				@ps_scope,
				@as_of_date,
				@date_basis,
				@ps_purpose,
				@ps_type,
				@read_only,
				dbo.cdosys_Version(),
				@as_id_1,
				@as_id_2,
				@as_id_3,
				@as_id_4,
				@proj_source,
				@ps_compl_cash_basis,
				@comments,
				@begin_date, --Virtus
				@trs_position_type, --Virtus
				@user_id,
				CURRENT_TIMESTAMP,
				@user_id,
				CURRENT_TIMESTAMP,
				@vrts_ps_type,
				@cash_date_basis, --Virtus - (APPDEV-3047)
				@run_ps_tests,			-- (IE-1523) 
				@ps_classification_code -- (IE-1523) 
				)

			SELECT @ps_id = SCOPE_IDENTITY();

		END			
		ELSE
			UPDATE dbo.PS_Portfolio_Snapshot
			SET
				ps_description = @ps_description,
				as_of_date = @as_of_date,
				ps_purpose = @ps_purpose,
				read_only = @read_only,
				as_id_1 = @as_id_1,
				as_id_2 = @as_id_2,
				as_id_3 = @as_id_3,
				as_id_4 = @as_id_4,
				comments = @comments,
				begin_date = @begin_date, --Virtus
				trs_position_type = @trs_position_type, --Virtus
				last_updated_by = @user_id, 
				last_update_date = CURRENT_TIMESTAMP
			WHERE
				ps_id = @ps_id;


		SELECT
			@pk_id = @ps_id,
			@operation_primary_key = 'ps_id;' + CAST(@ps_id AS varchar);
	

		--Success--
		EXEC dbo.cdosys_End_Procedure 
			@proc_id = @@procid,
			@user_id = @user_id,
			@silent_mode = @silent_mode,
			@starting_tran_count = @tran_count,	
			@pk_id = @pk_id, 
			@operation_confirmed = @operation_confirmed,
			@operation_details = @operation_details,
			@operation_primary_key = @operation_primary_key,
			@message_code = @message_code;	

		IF @@trancount > @tran_count
			COMMIT TRANSACTION @proc_name;
	
	END TRY
	BEGIN CATCH 
	
		IF @@trancount > 0
		BEGIN
	
			DECLARE @stack TABLE (stack_id int primary key clustered, stack_type varchar(25) NOT NULL, proc_id int NOT NULL, nest_level int NOT NULL, stack_message nvarchar(4000) NULL, stack_xml XML NULL);

			INSERT INTO @stack (stack_id, stack_type, proc_id, nest_level, stack_message, stack_xml)
				SELECT stack_id, stack_type, proc_id, nest_level, stack_message, stack_xml FROM dbo.cdosys_Stack_List(@@procid, @@nestlevel, NULL);
		
			IF XACT_STATE() = -1
				ROLLBACK TRANSACTION;
			ELSE IF @@trancount > @tran_count
				ROLLBACK TRANSACTION @proc_name;
	
			INSERT INTO dbo.cdosys_Stack(spid, proc_id, nest_level, stack_type, stack_message, stack_xml)
				SELECT @@spid, proc_id, nest_level, stack_type, stack_message, stack_xml FROM @stack;
		END
	
		EXEC dbo.cdosys_Return_UI @proc_id = @@procid, @pk_id = @pk_id, @operation_primary_key = @operation_primary_key, @starting_tran_count = @tran_count;
			
	END CATCH
END;


go


USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[VRTS_DDA_Director_list]    Script Date: 7/1/2019 1:53:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[VRTS_DDA_Director_list]

/*******************************************************************
* PURPOSE: Retrieves main list of all active directors
* NOTES: IE-1863
* CREATED:	07/01/2019	Yokesh Ram
* MODIFIED 
* DATE		AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
* 
*******************************************************************/

	@user_id user_id = NULL,
	@system_setup tinyint = 0, /* 0 = used for main deal list; 1 = used for system setup */
	@issue_id_to_be_added int = NULL, /* issue ID to be added to deal */
	@facility_id_to_be_added int = NULL, /* facility ID to be added to deal */
	@terminated_deals bit = NULL, 
	@exclude_test_deals bit = NULL,
	@exclude_mid_office_deals bit = NULL,
	@exclude_synthetic bit = NULL,
	@exclude_ref_portfolio bit = NULL,
	@exclude_cash_portfolio bit = NULL,
	@end_date datetime = NULL,
	@exclude_inactive_deals bit = null
AS
BEGIN

	SET NOCOUNT ON

	select distinct vda.agent_name
	from vrts_Deal_agent vda
	join cdosa_user cu on vda.agent_name = cu.first_name+' '+cu.last_name
	where agent_type = 'VCM'
		and active = '1' 	
		and first_name+' '+last_name not in ('VP Proxy','Test User','CDO NEXUS')
	order by agent_name


END

go

USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[VRTS_DDA_Entity_list]    Script Date: 7/3/2019 10:44:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[VRTS_DDA_Entity_list]

/*******************************************************************
* PURPOSE: Retrieves main list of all deals
* NOTES: 
* CREATED:
* MODIFIED 
* DATE		AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
* 04/17/2013	WWu		<CDOSBAU-3020>
* 07/03/2019	YR		IE-1863 Adding director list to return deals for the directors
*******************************************************************/

	@user_id user_id = NULL,
	@system_setup tinyint = 0, /* 0 = used for main deal list; 1 = used for system setup */
	@issue_id_to_be_added int = NULL, /* issue ID to be added to deal */
	@facility_id_to_be_added int = NULL, /* facility ID to be added to deal */
	@terminated_deals bit = NULL, 
	@exclude_test_deals bit = NULL,
	@exclude_mid_office_deals bit = NULL,
	@exclude_synthetic bit = NULL,
	@exclude_ref_portfolio bit = NULL,
	@exclude_cash_portfolio bit = NULL,
	@end_date datetime = NULL,
	@exclude_inactive_deals bit = null,
	@director_list varchar(max) = null	-- IE-1863
AS

SET NOCOUNT ON

IF @system_setup = 0 BEGIN

	-- IE-1863
	declare @tmp_director_list table (director varchar(500))

	insert into @tmp_director_list (director)
	select record_string
	from dbo.tf_split(@director_list, ';')

	insert into @tmp_director_list (director)
	values ('Virtus')
	-- IE-1863

	DECLARE @Entity_List TABLE (
		"ID" int,
		"Deal Nickname" varchar(500),
		entity_id int,
		deal_nickname varchar(500),
		sort_order int,
		director varchar(500)	-- IE-1863
	)

	INSERT @Entity_List

	SELECT
		"ID" = e.entity_id,
		"Deal Nickname" = e.deal_name,
		e.entity_id,
		deal_nickname = e.deal_name,
		sort_order = 1,
		(select agent_name from (select agent_name, row_number() over (partition by entity_id,agent_type order by deal_agent_id desc) rank	-- IE-1863
				from [dbo].[vrts_Deal_agent] vda where vda.agent_type = 'VCM' and vda.entity_id = e.entity_id) a where rank = 1)
	FROM
		dbo.Entity e
		LEFT OUTER JOIN dbo.Issuer i ON e.issuer_id = i.issuer_id
	WHERE
		dbo.cdosa_DealAccess(@user_id, e.entity_id) >= 0 

	UNION SELECT 
		0,
		'CITI Global DDA',
		0,
		'CITI Global DDA',
		0,
		'Virtus'	-- IE-1863
	ORDER BY
		sort_order, deal_name

	IF @terminated_deals = 1  and @end_date is not null BEGIN
		DELETE FROM @Entity_List
		FROM @Entity_List el JOIN Entity e ON el.entity_id = e.entity_id
		WHERE e.actual_term_dt < @end_date
	END

	IF @exclude_test_deals = 1 BEGIN
		DELETE FROM @Entity_List
		FROM @Entity_List el JOIN cdosys_Deal_Configuration dc ON el.entity_id = dc.entity_id
		WHERE config_code = 'test_deal' and config_value = '1'	
	END

	IF @exclude_mid_office_deals = 1 BEGIN
		DELETE FROM @Entity_List
		FROM @Entity_List el JOIN cdosys_Deal_Configuration dc ON el.entity_id = dc.entity_id
		WHERE config_code = 'middle_office_deal' and config_value = '1'	
	END

	IF @exclude_synthetic = 1 BEGIN
		DELETE FROM @Entity_List
		FROM @Entity_List el JOIN Entity e ON el.entity_id = e.entity_id
		WHERE e.deal_type = 'SYN'
	END

	IF @exclude_ref_portfolio = 1 BEGIN
		DELETE FROM @Entity_List
		FROM @Entity_List el JOIN Entity e ON el.entity_id = e.entity_id
		WHERE e.deal_type = 'REF'
	END

	IF @exclude_cash_portfolio = 1 BEGIN
		DELETE FROM @Entity_List
		FROM @Entity_List el JOIN cdosys_Deal_Configuration dc ON el.entity_id = dc.entity_id
		WHERE config_code = 'cash_portfolio' and config_value = '1'	
	END

	if @exclude_inactive_deals = 1 begin
		DELETE FROM @Entity_List
		from @Entity_List el join entity e on el.entity_id = e.entity_id
		where entity_status = 'I'
	end

	if (select count(*) from @tmp_director_list) > 1
	begin
		SELECT * 
		FROM @Entity_List
		where director in (select director
							from @tmp_director_list)
	end
	else
	begin
		SELECT * FROM @Entity_List
	end
	
END


go


USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[VRTS_PS_Generate_Extended]    Script Date: 6/28/2019 2:24:43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [dbo].[VRTS_PS_Generate_Extended]

/*******************************************************************
* PROCEDURE: 
* PURPOSE: 
* NOTES: 
* CREATED: 9/25/2006
* MODIFIED 
* DATE		AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
* 10/11/2007	TG		Added call to VRTS_PS_Generate_accrual for TRS deals
* 10/29/2007	TG		Added initial_purchase_price and initial_purchase_date to nex_ps_principal_reduction
* 11/07/2007	TG		Changed WHERE clause for nex_ps_principal_reduction to pull in anything that traded or settled when run on a trade date basis.
* 11/07/2007	TG		Added ftrade_id to nex_ps_principal_reduction
* 11/26/2007	TG		Added current_price to nex_ps_principal_reduction
* 11/30/2007	TG		Added country_name to nex_ps_principal_reduction
* 12/19/2007	TimP	Added code for written downs
* 12/20/2007	TG		Added code to create @discretionary_trades_beginning_balance_override
* 12/20/2007	TG		Updated deal variable creation so that it will test to see if each deal variable exists instead of just testing to see if @transaction_range_type exists
* 12/20/2007	TG		Change standard deal variables to work off of the table nex_deal_variable_standard
* 1/8/2008		TimP	Added Exec NEX_Prior_Ratings to update prior ratings udf
* 1/16/2008		TimP	Put NEX_Process_Snaphot_Variables after PS_Tool_run
* 01/30/2008	TG		Added call to VRTS_PS_Principal_Balance_generate
* 2/8/2008		TimP	Added code to update UDF facility_fee_pct_UDF
* 02/13/2008	TG		Moved SQL that gets @deal_type to the top of the SP
* 2/13/2008		TG		Changed SQL that populates nex_ps_principal_reduction to pull in based on cash_date for TRS deals.
* 02/13/2008	SRD		Updated insert into NEX_PS_Principal_reduction to improve performance
* 02/13/2008	TG		Commented out SRD change above.  It doesn't get the same data as the original.
* 02/21/2008	TG		Removed the if statment from VRTS_PS_Generate_accrual.  We want to run this on all deal types now to get the accruals into the snapshot.
* 03/07/2008	TG		Added currency_code to nex_ps_principal_reduction
* 03/07/2008	TG		Added currency_code to nex_ps_cash_transaction
* 03/08/2008	TimP	Changed join for performance
* 04/11/2008	TimP	per Bob took out i.facility_id = on INSERT INTO nex_ps_issuer_rating
* 04/11/2008	TimP	Fix for written downs
* 06/13/2008	TimP	Changed the way data is inserted to nex_ps_asset_rating
* 08/14/2008    TimB	Added PIK section to correct pik factors.
* 04/30/2009	SD		removed call to [VRTS_PS_Generate_asset_rating] (populates nex_ps_asset_rating)
* 03/22/2010	MMR		6.5 Recon. Change ftrans.trans_cash_amount to ftc.trans_cash_amount
* 06/10/2010	RA		Added call to VRTS_PS_TRS_Recalc_Update_Swap_Interest to recalculate swap rate
*						for libor_floor and non performing assets (TRS-322)
* 08/24/2010	RA		Added an update statement to update the purchase price with the override value (TRS-376)
* 01/12/2011	RA		Added a call to a new stored procedure "VRTS_PS_Adjust_Synthetic_Accruals" to 
*						adjust the interest on accruals for synthetic assets (TRS-373)
* 01/12/2011	RA		Changed the INSERT INTO ps_item_custom statement to insert only the records which are
*						not already present in ps_item_custom table. (TRS-454)
* 11/14/2011	TL		Modified the WHERE clause to update the purchase price for TRS on line 232 (TRS-645)
*						will use "ABS((ftrade.original_trade_price * 100) - purchase_price) > .00001"
                        instead of "ABS(ftrade.original_trade_price - ftrade.effective_trade_price) > .00001"
* 01/13/2012	TB		Implemented secondary call to recalculate principal balances based on the latest recovery rate derivations  (Telos)
*04/10/2012		Wu	updated [issue_current_par_amount],[issue_original_face_amount],[issue_principal_balance] of PS_Issue
*10/11/2013		RA		Added account_id to the JOIN when saving data nex_ps_trade_date_cash_adjustments table (CDOSBAU-3857)
*05/01/2014		TL		Modified Short_Position_UDF to Item level rather than security/facility. (CDOSBAU-4793)
*05/23/2014		TL		Modified to update 4 new columns for ps_item(CSAMRPTS-562)
*06/16/2014		RA		Added status_code, facility_id, issue_id, and principal_code columns to 
*						nex_ps_trade_date_cash_adjustments table (CSAMRPTS-588 & CSAMRPTS-519)
*07/18/2014		RA		Added update statement to populate new WAPP_TRD and WAPP_STLD fields which
*						are still blank (CDOSBAU-5152)
*09/22/2014		RA		Added logic to update principal balance exposure columns in PS_Issue and PS_Item tables (CDOSBAU-5438) 
*02/10/2015		SI		Added logic to adjust Cash_transactions for Hedges in Acountin Balances(Snapshot Date Basis) - (CDOSBAU-5886)
*04/08/2015		SI		Hedges "Swap FX Rate" formula change - (CDOSBAU-6665)
*05/19/2015		RA		Added update statement to populate new CSLLI_DM3_B and CSLLI_DM3_BB fields (CDOSBAU-6994)
*05/29/2015		IO		Modified code to populate new industry fields - moody_issuer_industry_Description, 
                        sp_issuer_industry_Description and fitch_issuer_industry_Description(CDOSBAU-7013)
*04/07/2016		SRD		added .dbo CDOSBAU-9287
*11/03/2016		SI		Add Gains & Loss Data - (APPDEV-1448)
*12/20/2017		SI		Adding new Parameter for Transaction Date CASH -- (APPDEV-3047)
*08/23/2018		RA		Added new @regen_data parameter and logic to update existing snapshot data (STRAT-835)
*08/30/2018		RA		Added new @regen_data parameter in call for VRTS_PS_Generate_principal_reduction (STRAT-840)
*09/10/2018     APP     Add Missing Hedges in Account Balances (Snapshot Date Basis) (APPDEV-3108) 
*10/24/2018		PM		Add more trace log (IE-1452)
*06/28/2019		YR		IE-1823 Specifying columns in the insert statement for nex_snapshot_classification
*******************************************************************/

@ps_id int,
@vrts_ps_type varchar(4) = NULL,
@regen_data bit = 0

AS

SET NOCOUNT ON
SET ARITHABORT ON

DECLARE @entity_id int
DECLARE @use_effective_purchase_price int
DECLARE @period_begin smalldatetime
DECLARE @as_of_date smalldatetime
DECLARE @date_basis varchar(4)
DECLARE @deal_type varchar(4)
DECLARE @has_trans_sum tinyint
DECLARE @transaction_begin datetime
DECLARE @transaction_range_type varchar(4)
DECLARE @manual_date datetime	
DECLARE @exists tinyint
-- SI 02/10/2015 (CDOSBAU-5886)
DECLARE @base_currency varchar(5)
DECLARE @cash_date_basis lookup_code -- (APPDEV-3047)

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'BEGIN'
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS_Begin_VRTS_PS_Generate_Extended'

--insert aaa_mmr values ('VRTS_PS_Generate_Extended', 'BEGIN')

SELECT 
    @as_of_date = as_of_date, 
    @date_basis = date_basis, 
    @entity_id = entity_id ,
    @cash_date_basis = cash_date_basis -- (APPDEV-3047)
FROM 
    dbo.ps_portfolio_snapshot 
WHERE 
    ps_id = @ps_id

--insert aaa_mmr values ('@date_basis', @date_basis)

SELECT 
    @deal_type = deal_type ,
    -- SI 02/10/2015 (CDOSBAU-5886)
    @base_currency = base_currency 
FROM 
    dbo.entity 
WHERE 
    entity_id = @entity_id

SET @period_begin = dbo.NEX_getDeterminationDate(@ps_id)
IF @period_begin IS NULL BEGIN
    SET @period_begin = '1901-01-01'
END

/* Insert our standard deal variables if they don't exist */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_standard_deal_variables'
EXEC dbo.VRTS_PS_Generate_standard_deal_variables @ps_id = @ps_id
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_standard_deal_variables'

--insert aaa_mmr values ('PS_Generation_summary_put just executed', 'VRTS - VRTS_PS_Generate_standard_deal_variables')

IF @deal_type = 'TRS' BEGIN
    /* <effective_purchase_price_UDF> */
    INSERT INTO ps_item_custom
        (
        ps_item_id, 
        field_id, 
        field_value, 
        field_value_desc
        )
        SELECT 
            ps_item_id,
            10452,
            CAST(CONVERT(DECIMAL (16,13), dbo.nex_getFacilityItemEffectivePurchasePrice(item_id)*100) AS varchar) field_value,
            CAST(CONVERT(DECIMAL (16,13), dbo.nex_getFacilityItemEffectivePurchasePrice(item_id)*100) AS varchar) field_value_desc
        FROM
            dbo.ps_item pit 
        WHERE 
            pit.ps_id = @ps_id AND
            dbo.nex_getFacilityItemEffectivePurchasePrice(item_id) IS NOT NULL AND
            ps_item_id NOT IN (
                                SELECT 
                                    psic.ps_item_id 
                                FROM 
                                    dbo.ps_item_custom psic 
                                JOIN 
                                    dbo.ps_item psi 
                                    ON psic.ps_item_id = psi.ps_item_id AND
                                        psic.field_id = 10452
                                WHERE ps_id = @ps_id
                            )
    /* </effective_purchase_price_UDF> */
END


/* <Adjust transaction date for deals that require more txn data for the transaction summarization test(s)> */
SELECT 
    @transaction_range_type = variable_value
FROM
    dbo.nex_deal_variable
WHERE 
    entity_id = @entity_id AND 
    variable_name = '@transaction_range_type'

--insert aaa_mmr values ('@transaction_range_type', @transaction_range_type)

-- Only default if it is NOT set
IF @transaction_range_type IS NULL BEGIN
    SELECT 
        @has_trans_sum = count(*) 
    FROM 
        dbo.deal_test 
    WHERE 
        test_id = 60 AND 
        entity_id =  @entity_id

    IF @has_trans_sum > 0 BEGIN	
        SET @transaction_range_type = 'INCP'		
    END ELSE BEGIN	
        SET @transaction_range_type = 'DUE'
    END
    
    UPDATE dbo.nex_deal_variable SET 
        variable_value = @transaction_range_type
    WHERE
        entity_id = @entity_id AND 
        variable_name = '@transaction_range_type'

END
/* </Adjust transaction date for deals that require more txn data for the transaction summarization test(s)> */


DECLARE
    @Last_Approved_PS int,
    @Last_Approved_PS_as_of_date datetime,
    @Lesser_Date datetime,
    @date_list varchar(100)

SET @Last_Approved_PS = dbo.nex_getPriorSnapshot(@ps_id, default)
SELECT @Last_Approved_PS_as_of_date = as_of_date FROM dbo.ps_portfolio_snapshot WHERE ps_id = @Last_Approved_PS

SELECT @manual_date = variable_value from dbo.nex_deal_variable where entity_id = @entity_id and variable_name = '@transaction_start_date'

SELECT @transaction_begin = case @transaction_range_type 
                                when 'INCP' then '01/01/1900' 
                                when 'DUE' then @period_begin 
                                when 'MAN' then @manual_date 
                                when 'LAPS' then @Last_Approved_PS_as_of_date END

--insert aaa_mmr values ('Starting Puts', 'PS_Generation_summary_put')

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_deal_reporting_udf'
EXEC dbo.VRTS_PS_Generate_deal_reporting_udf @ps_id = @ps_id
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_deal_reporting_udf'

IF NOT EXISTS(SELECT 1 FROM dbo.nex_snapshot_classification WHERE ps_id = @ps_id) BEGIN
	INSERT INTO dbo.nex_snapshot_classification (ps_id,classification_code,created_by,create_date,last_updated_by,last_update_date, row_version)	-- IE-1823
	VALUES (@ps_id, 'NA', NULL, NULL, NULL, NULL, NULL)		-- IE-1823
END

--EXEC VRTS_PS_Generate_asset_rating @ps_id = @ps_id
--EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_asset_rating'

IF @regen_data != 1 BEGIN
	EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_liability_info'
	EXEC dbo.VRTS_PS_Generate_liability_info @ps_id = @ps_id
	EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_liability_info'

END

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_issuer_rating'
EXEC dbo.VRTS_PS_Generate_issuer_rating @ps_id = @ps_id
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_issuer_rating'

--fix the prices in the ps_item table - cdo suite inserts the effective price, we want the original price unless the deal setting (use_effective_purchase_price) says to use the effective
SET @use_effective_purchase_price = dbo.nex_getDealSetting(@entity_id, 'use_effective_purchase_price')

IF @regen_data != 1 BEGIN
	IF CAST(ISNULL(@use_effective_purchase_price,0) AS tinyint) != 1 BEGIN

		UPDATE dbo.ps_item SET 
			purchase_price = original_trade_price * 100
		FROM 
			dbo.ps_item
			JOIN dbo.facility_item fitem ON 
				ps_item.item_id = fitem.fitem_id AND
				fitem.entity_id = @entity_id
			JOIN dbo.facility_transaction ftran ON fitem.facility_trans_id = ftran.facility_trans_id
			JOIN dbo.facility_trade ftrade ON 
				ftran.ftrade_id = ftrade.ftrade_id AND
				-- ABS(ftrade.original_trade_price - ftrade.effective_trade_price) > .00001
				ABS((ftrade.original_trade_price * 100) - purchase_price) > .00001
		WHERE 	
			ps_item.ps_id = @ps_id
		
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - update price with effective price'
		
	END

	EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'update the purchase price with override value'
	-- update the purchase price with override value (TRS-376)
	UPDATE dbo.ps_item SET 
		purchase_price = CAST(dbo.ItemCustomIdentifier(ps_item.item_id, 'IMPLIED_PURCH_PRICE_UDF') AS float)
	WHERE 	
		ps_item.ps_id = @ps_id AND
		dbo.ItemCustomIdentifier(ps_item.item_id, 'IMPLIED_PURCH_PRICE_UDF') IS NOT NULL
END

/* Store the manual deal variables */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'Store the manual deal variables'

DECLARE @dv_manual_value TABLE (
	ps_id int,
	variable_id int,
	effective_date datetime,
	variable_value varchar(8000),
	nex_ps_deal_variable_manual_value_id int
)

INSERT INTO @dv_manual_value (
		ps_id, 
		variable_id, 
		effective_date, 
		variable_value
	)
	SELECT
		@ps_id, 
		dvmv.variable_id, 
		dvmv.effective_date, 
		dvmv.variable_value
	FROM
		dbo.nex_deal_variable dv
		JOIN dbo.nex_deal_variable_manual_value dvmv ON dv.variable_id = dvmv.variable_id
	WHERE
		dv.entity_id = @entity_id

-- get the primary key for the matching records
UPDATE
	dmv
SET
	nex_ps_deal_variable_manual_value_id = pdmv.nex_ps_deal_variable_manual_value_id
FROM
	@dv_manual_value dmv
JOIN
	dbo.NEX_PS_deal_variable_manual_value pdmv
	ON pdmv.ps_id = @ps_id
		AND pdmv.ps_id = dmv.ps_id
		AND pdmv.variable_id = dmv.variable_id
		AND pdmv.effective_date = dmv.effective_date
WHERE
	pdmv.ps_id = @ps_id

-- delete records which are no longer present in new data
DECLARE @deleted_dv_manual TABLE (
	nex_ps_deal_variable_manual_value_id int
)

INSERT INTO @deleted_dv_manual (
		nex_ps_deal_variable_manual_value_id
	)
	SELECT
		pdmv.nex_ps_deal_variable_manual_value_id
	FROM
		dbo.NEX_PS_deal_variable_manual_value pdmv
	LEFT JOIN
		@dv_manual_value dmv
		ON dmv.nex_ps_deal_variable_manual_value_id = pdmv.nex_ps_deal_variable_manual_value_id
			AND pdmv.ps_id = @ps_id
	WHERE
		pdmv.ps_id = @ps_id
		AND dmv.nex_ps_deal_variable_manual_value_id IS NULL 

DELETE
	pdmv
FROM
	dbo.NEX_PS_deal_variable_manual_value pdmv
JOIN
	@deleted_dv_manual dmv
	ON dmv.nex_ps_deal_variable_manual_value_id = pdmv.nex_ps_deal_variable_manual_value_id
		AND pdmv.ps_id = @ps_id
WHERE
	pdmv.ps_id = @ps_id

-- update matching records based on primary key
UPDATE
	pdmv
SET
	variable_value = dmv.variable_value
FROM
	dbo.NEX_PS_deal_variable_manual_value pdmv
JOIN
	@dv_manual_value dmv
	ON dmv.nex_ps_deal_variable_manual_value_id = pdmv.nex_ps_deal_variable_manual_value_id
WHERE
	dmv.nex_ps_deal_variable_manual_value_id IS NOT NULL

-- add new records
INSERT INTO dbo.NEX_PS_deal_variable_manual_value (
		ps_id, 
		variable_id, 
		effective_date, 
		variable_value
	)
	SELECT
		ps_id, 
		variable_id, 
		effective_date, 
		variable_value
	FROM
		@dv_manual_value
	WHERE
		nex_ps_deal_variable_manual_value_id IS NULL

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'Insert into NEX_PS_deal_variable_manual_value'
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - Insert into NEX_PS_deal_variable_manual_value'

/* Get Date for NEX_PS_Cash_Transaction */

-- TG Added isnull around some of the dates so @date_list wouldn't be NULL
SET @date_list = convert(varchar, @transaction_begin, 101) 
                + ';' + convert(varchar, ISNULL(@Last_Approved_PS_as_of_date, @transaction_begin), 101) 
                + ';' + convert(varchar,ISNULL(@period_begin, @transaction_begin), 101) 
SELECT @Lesser_Date = dbo.vrts_Evaluate_date ('MIN', @date_list)

IF @regen_data != 1 BEGIN
/* Store Cash Transactions for the period */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_cash_transaction'
EXEC dbo.VRTS_PS_Generate_cash_transaction @ps_id = @ps_id, @begin_date = @Lesser_Date
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_cash_transaction'


/* <Adjust trade date cash using pending trade data> */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'Adjust trade date cash using pending trade data'
IF @date_basis = 'TRD' AND @deal_type != 'TRS' BEGIN
        DECLARE 
            @account_id varchar(10),
            @Princ_Proc float,
            @Inter_Proc float,
            @Misc_Proc float,
            @deal_data_value varchar(4000),
            @deal_data_value_orig varchar(4000),
            @qryCount int

        DECLARE @Cash_Trans TABLE 
            (
            account_id int,	
            princ_proc float,
            inter_proc float,
            misc_proc float,
            qryCount int,
            -- SI 02/10/2015 (CDOSBAU-5886)
            hedge_id int 
            )

		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'INSERT INTO dbo.nex_ps_trade_date_cash_adjustments'
        INSERT INTO dbo.nex_ps_trade_date_cash_adjustments
            (
                ps_id,
                trans_description,
                settlement_status,
                trade_id,
                issuer_name,
                asset_name,
                identifier_type,
                identifier,
                trade_date,
                expected_settlement_date,
                settlement_date,
                currency_code,
                original_commitment_amount,
                permanent_reductions,
                final_commitment_amount,
                trade_price,
                accrued_interest,
                effective_trade_amount,
                effective_trade_amount_principal,
                effective_trade_amount_interest,
                effective_trade_amount_misc,
                funded_percentage,
                principal_code, 
                facility_id, 
                issue_id, 
                status_code
            )
            SELECT 
                @ps_id ps_id,
                pt.trans_description,
                CASE
                    WHEN pt.settle_date IS NULL THEN 
                        'Unsettled'
                    ELSE 
                        'Settled'
                END settlement_status,
                ISNULL(pt.ftrade_id, pt.issue_trans_id) trade_id,
                pt.issuer_name,
                pt.asset_name,
                dbo.nex_getIdentifierType_EntityID(NULL, pt.issue_id, pt.facility_id, pt.entity_id) identifier_type,
                dbo.nex_getIdentifier_EntityID(NULL, pt.issue_id, pt.facility_id, pt.entity_id) identifier,
                pt.trans_date trade_date,
                pt.expected_settle_date expected_settlement_date,
                pt.settle_date settlement_date,
                pt.currency_code,
                pt.original_trade_amount original_commitment_amount,
                pt.reduction_amount permanent_reductions,
                pt.final_trade_amount /*+ 
                    CASE WHEN CAST(dbo.ConfigValue('include_reductions_in_trade_date_deal', ftrade.entity_id) AS int) = 1 
                            THEN ISNULL(ftran_econ_benefit.trans_cash_amount, 0) 
                        ELSE 0 
                    END*/ final_commitment_amount,
                pt.price trade_price,
				dbo.CodeDesc('TRADE_ACCRUED_INT_TYPE', ISNULL(ftrade.trade_accrued_int_type, itrans.trade_accrued_int_type)) accrued_interest,
	--			/*ISNULL(actv.princ_proceeds_amt,0) + ISNULL(actv.int_proceeds_amt,0) + ISNULL(actv.misc_proceeds_amt,0) +*/ ISNULL(ftran_econ_benefit.trans_cash_amount,0) effective_trade_amount,
	--			ISNULL(actv.princ_proceeds_amt,0) + ISNULL(ftran_econ_benefit.princ_proceeds_amt,0) effective_trade_amount_principal,
	--			ISNULL(actv.int_proceeds_amt,0) + ISNULL(ftran_econ_benefit.int_proceeds_amt,0) effective_trade_amount_interest,
	--			ISNULL(actv.misc_proceeds_amt,0) + ISNULL(ftran_econ_benefit.misc_proceeds_amt,0) effective_trade_amount_misc,
				pt.effective_trade_amount,
                pt.principal_proceeds_amount effective_trade_amount_principal,
                pt.interest_proceeds_amount effective_trade_amount_interest,
                null, 
                -- RA 6/16/2014 (CSAMRPTS-588)
                pt.funded_percentage,
                pt.principal_code, 
                pt.facility_id, 
                pt.issue_id, 
                status_code = Virtustrade.dbo.fn_EventHistoryStatusASofDate(ISNULL(pt.ftrade_id, pt.issue_trans_id), NULL, @entity_id, 'C', 'status_code', NULL, @as_of_date)
            FROM 
                dbo.vrts_tf_pending_trades_roll_up (@as_of_date, @entity_id, DEFAULT) pt
                LEFT JOIN dbo.Account_Transaction_expanded_view actv ON ISNULL(pt.facility_trans_id, pt.issue_trans_id) = actv.trans_id AND pt.account_id = actv.account_id
                LEFT JOIN dbo.facility_trade ftrade ON pt.ftrade_id = ftrade.ftrade_id
                LEFT JOIN dbo.issue_transaction itrans ON pt.issue_trans_id = itrans.issue_trans_id
                LEFT JOIN
                    (
                    SELECT
                        ftrans.ftrade_id,
                        MAX(ftrans.facility_trans_id) facility_trans_id,
                        SUM(ftc.trans_cash_amount) trans_cash_amount,
                        SUM(acct_tran.princ_proceeds_amt) princ_proceeds_amt, 
                        SUM(acct_tran.int_proceeds_amt) int_proceeds_amt, 
                        SUM(acct_tran.misc_proceeds_amt) misc_proceeds_amt 
                    FROM
                        dbo.VRTS_facility_transaction_view ftrans
                        JOIN dbo.account_transaction acct_tran ON ftrans.facility_trans_id = acct_tran.facility_trans_id
                        JOIN dbo.Facility_Transaction_Cash ftc on ftrans.facility_trans_id = ftc.facility_trans_id AND
                        ftrans.trans_currency = ftc.amount_currency
                    WHERE
                        ftrans.trans_type ='LPEB'
                    GROUP BY
                        ftrans.ftrade_id
                    ) ftran_econ_benefit ON ftrade.ftrade_id = ftran_econ_benefit.ftrade_id
                LEFT JOIN VirtusTrade.dbo.PS_Excluded_Trade et ON
                ISNULL(pt.ftrade_id, pt.issue_trans_id) = et.trade_id AND et.ps_id = @ps_id

            WHERE
                et.trade_id IS NULL


        --Get pending Trades excluding fees.  Pulling the amounts from account_transaction_expanded_view excludes the fees.
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'Get pending Trades excluding fees'

        INSERT INTO @Cash_Trans
            (
                account_id,	
                princ_proc,
                inter_proc,
                misc_proc,
                qryCount,
                hedge_id
            )
        
        SELECT 
            pt.account_id,
            SUM(pt.principal_proceeds_amount),
            SUM(pt.interest_proceeds_amount),
            SUM(pt.misc_proceeds_amount),
            count(*),
            -- SI 02/10/2015 (CDOSBAU-5886)
            MAX(h.hedge_id)  

        FROM 
            dbo.vrts_tf_pending_trades (@as_of_date, @entity_id, DEFAULT) pt LEFT JOIN VirtusTrade.dbo.PS_Excluded_Trade et ON
            ISNULL(pt.ftrade_id, pt.issue_trans_id) = et.trade_id AND et.ps_id = @ps_id
            -- SI 02/10/2015 (CDOSBAU-5886)
            LEFT JOIN dbo.Hedge h ON pt.lot_id = h.item_id AND h.entity_id = pt.entity_id

        WHERE
            et.trade_id IS NULL
            
        GROUP BY
            pt.account_id


        SELECT 
            @deal_data_value = deal_data_value		
        FROM 
            dbo.PS_Deal_Data 
        WHERE 
            ps_id = @ps_id AND 
            deal_data_type = 'CASH'

        

        DECLARE @balances_string varchar(1000),
                @i int

        DECLARE @t TABLE
            (
            account_id int,
            princ_proc float,
            inter_proc float,
            misc_proc float
            )


        INSERT INTO @t
            (
            account_id,
            princ_proc,
            inter_proc,
            misc_proc
            )
        SELECT  
            dbo.StringToken(record_string, ';', 1),
            SUM(convert(float,dbo.StringToken(record_string, ';', 2))),
            SUM(convert(float,dbo.StringToken(record_string, ';', 3))),
            SUM(convert(float,dbo.StringToken(record_string, ';', 4)))
        FROM 
            dbo.tf_Split(@deal_data_value, '|')
        GROUP BY 
            dbo.StringToken(record_string, ';', 1)

        IF @cash_date_basis != 'TRAN' BEGIN -- (APPDEV-3047) -- Do Not Add Pending Trade if Snapshot is Tansaction Date Basis
            UPDATE 
                ab
            SET
                princ_proc = isnull(ab.princ_proc, 0) + isnull(ct.princ_proc,0),
                inter_proc = isnull(ab.inter_proc, 0) + isnull(ct.inter_proc,0),
                misc_proc = isnull(ab.misc_proc, 0) + isnull(ct.misc_proc,0)
            FROM
                @t ab JOIN @Cash_Trans ct ON
                ab.account_id = ct.account_id

            INSERT INTO @t(
                            account_id,
                            princ_proc,
                            inter_proc,
                            misc_proc
                            )
                SELECT
                    ct.account_id,
                    isnull(ct.princ_proc,0),
                    isnull(ct.inter_proc,0),
                    isnull(ct.misc_proc,0)
                FROM
                    @Cash_Trans ct LEFT JOIN @t ab  ON
                    ct.account_id = ab.account_id
                WHERE
                    ab.account_id is null
        END -- (APPDEV-3047)
                
        -- SI 02/10/2015 (CDOSBAU-5886)
        --  Code Start 
        --Hedges Cash Transactions Adjustemnt for Account Balances( Snapshot Date Basis)
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'Hedges Cash Transactions Adjustemnt for Account Balances'
        IF EXISTS (Select hedge_id FROM @Cash_Trans ) BEGIN
            
            DECLARE @hedge_pending_trades TABLE	 
                                (	hedge_id int,
                                    facility_id int,
                                    issue_id int,
                                    trans_type lookup_code,
                                    trans_description varchar(200),
                                    principal_proceeds_amount money,
                                    interest_proceeds_amount money,
                                    misc_proceeds_amount money,
                                    account_id int,
                                    spot_fx_rate float,
                                    proceeds_type char(1),
                                    deal_account_id int,
                                    sub_entity_id int -- APPDEV-3108
                                    )
            
            INSERT INTO	 @hedge_pending_trades		
            -- Get Hedges for Principal Proceeds and Proceeds_type		
            SELECT	h.hedge_id , 
                    pt.facility_id, 
                    pt.issue_id, 
                    pt.trans_type, 
                    pt.trans_description ,
                    pt.principal_proceeds_amount ,
                    null,
                    pt.misc_proceeds_amount,
                    pt.account_id,
                    spot_fx_rate = CASE WHEN ISNULL(h.from_currency_exchange_rate,0) != 1 THEN h.from_currency_exchange_rate ELSE 1/nullIf(h.to_currency_exchange_rate,0) END,
                    ISNULL(MIN(m.proceeds_type),'P'), -- APPDEV-3108
                    Null,
                    m.sub_entity_id -- APPDEV-3108
            FROM dbo.vrts_tf_pending_trades(@as_of_date,@entity_id, 'RPT')pt
                JOIN dbo.Hedge h ON pt.lot_id = h.item_id
                LEFT JOIN dbo.Account_trans_type_map m ON m.account_id = pt.account_id  and m.trans_type = pt.trans_type --APPDEV-3108
                WHERE  @base_currency != pt.currency_code
            GROUP BY h.hedge_id , 
                    pt.facility_id, 
                    pt.issue_id, 
                    pt.trans_type, 
                    pt.trans_description ,
                    pt.principal_proceeds_amount ,
                    pt.misc_proceeds_amount,
                    pt.account_id,
                    h.from_currency_exchange_rate,
                    h.to_currency_exchange_rate,
                    m.sub_entity_id -- APPDEV-3108
            UNION
            -- Get Hedges for Interest Proceeds and Proceeds_type	
            SELECT	h.hedge_id , 
                    pt.facility_id, 
                    pt.issue_id, 
                    pt.trans_type, 
                    pt.trans_description ,
                    null ,
                    pt.interest_proceeds_amount,
                    null,
                    pt.account_id,
                    spot_fx_rate = CASE WHEN ISNULL(h.from_currency_exchange_rate,0) != 1 THEN h.from_currency_exchange_rate ELSE 1/nullIf(h.to_currency_exchange_rate,0) END,
                    ISNULL(MIN(m.proceeds_type),'I'),-- APPDEV-3108
                    Null,
                    m.sub_entity_id -- APPDEV-3108
            FROM dbo.vrts_tf_pending_trades(@as_of_date,@entity_id, 'RPT')pt
                JOIN dbo.Hedge h ON pt.lot_id = h.item_id
                LEFT JOIN dbo.Account_trans_type_map m ON m.account_id = pt.account_id  and m.trans_type = pt.trans_type -- APPDEV-3108
                WHERE  @base_currency != pt.currency_code
            GROUP BY h.hedge_id , 
                        pt.facility_id, 
                        pt.issue_id, 
                        pt.trans_type, 
                        pt.trans_description ,
                        pt.interest_proceeds_amount ,
                        pt.account_id,
                        h.from_currency_exchange_rate,
                        h.to_currency_exchange_rate,
                        m.sub_entity_id -- APPDEV-3108                 
            
            -- Get Deal Based Accounts
            DECLARE @deal_accounts	TABLE
                    (	account_id int,
                        trans_type lookup_code,
                        trans_type_desc varchar(200),
                        proceeds_type char(1),
                        sub_entity_id int, -- APPDEV-3108
                        currency VARCHAR(5) -- APPDEV-3108
                        )
            
            INSERT INTO @deal_accounts			
            SELECT
                m.account_id,
                cv.trans_type,
                cv.trans_type_desc, 
                proceeds_type = ISNULL(m.proceeds_type, dat.proceeds_type),
                m.sub_entity_id, -- APPDEV-3108
                m.trans_currency -- APPDEV-3108
            FROM dbo.Cash_trans_type_view cv
                LEFT OUTER JOIN dbo.cdobiz_Default_account_trans_type_map dat 
                    LEFT OUTER JOIN  dbo.Account_trans_type_map m 
                            JOIN Entity e ON m.entity_id = e.entity_id -- APPDEV-3108
                            JOIN dbo.Account a ON m.account_id = a.account_id
                            ON m.trans_type = dat.trans_type AND m.amount_type = dat.amount_type AND m.entity_id = @entity_id -- APPDEV-3108                            
                    ON cv.trans_type = dat.trans_type
            WHERE dat.amount_type IS NOT NULL
                AND m.trans_currency = @base_currency -- APPDEV-3108

            
            --  MAP each Hedge transaction to Deal Based Account_ID 
            UPDATE hpt
                SET deal_account_id = da.account_id
            FROM @hedge_pending_trades hpt
                JOIN @deal_accounts da On da.trans_type = hpt.trans_type 
                                        AND hpt.trans_description = da.trans_type_desc
                                        AND ISNULL(hpt.sub_entity_id,0) = ISNULL(da.sub_entity_id,0) -- APPDEV-3108
                                        AND hpt.proceeds_type = da.proceeds_type
                                        
            
            DECLARE @Hedge_Cash_Trans TABLE 
                    (
                    account_id int,	
                    princ_proc float,
                    inter_proc float,
                    misc_proc float							
                    )
                    
                
            --<-- APPDEV-3108>
			EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'APPDEV-3108'

            INSERT INTO @Hedge_Cash_Trans
                (
                account_id,	
                princ_proc,
                inter_proc,
                misc_proc
                )
            -- Adjust Converted Cash Transaction to matching Deal based Account_id	
            SELECT distinct 
                hpt.deal_account_id,
                SUM(hpt.principal_proceeds_amount * hpt.spot_fx_rate),
                SUM(hpt.interest_proceeds_amount * hpt.spot_fx_rate),
                SUM(hpt.misc_proceeds_amount * hpt.spot_fx_rate)
            FROM (SELECT distinct
                hpt.deal_account_id,
                hpt.principal_proceeds_amount,
                hpt.interest_proceeds_amount,
                hpt.misc_proceeds_amount,
                hpt.spot_fx_rate
            FROM @hedge_pending_trades hpt
            ) hpt
            GROUP BY hpt.deal_account_id
            --<-- APPDEV-3108 />
            INSERT INTO @Hedge_Cash_Trans
                (
                account_id,	
                princ_proc,
                inter_proc,
                misc_proc
                )
            --<-- APPDEV-3108> --Code Begin
                -- Adjust Cash Transaction to matching Trade Amount Principal
                -- it is  multiplicates by -1 because we are moving this cash to the EUR subentity
            SELECT distinct 
                hpt.account_id,
                SUM(hpt.principal_proceeds_amount * -1 ),
                SUM(hpt.interest_proceeds_amount * -1),
                SUM(hpt.misc_proceeds_amount * -1)
            FROM (SELECT distinct
                hpt.account_id,
                hpt.principal_proceeds_amount,
                hpt.interest_proceeds_amount,
                hpt.misc_proceeds_amount,
                hpt.spot_fx_rate
            FROM @hedge_pending_trades hpt
            ) hpt
            Group by hpt.account_id

                    
            UPDATE ab
            SET
                princ_proc = isnull(ab.princ_proc, 0) + isnull(hct.princ_proc,0),
                inter_proc = isnull(ab.inter_proc, 0) + isnull(hct.inter_proc,0),
                misc_proc = isnull(ab.misc_proc, 0) + isnull(hct.misc_proc,0)
            FROM
                @t ab JOIN @Hedge_Cash_Trans hct ON
                ab.account_id = hct.account_id
                    
            INSERT INTO @t
            SELECT
                hct.account_id,
                princ_proc = isnull(hct.princ_proc,0),
                inter_proc = isnull(hct.inter_proc,0),
                misc_proc = isnull(hct.misc_proc,0)
            FROM
                @Hedge_Cash_Trans hct 
            WHERE hct.account_id NOT IN (
                SELECT hct.account_id from @Hedge_Cash_Trans
                    JOIN @t ab ON
                ab.account_id = hct.account_id)
                
            DECLARE @Hedge_Cash_Trans_Base_Account TABLE 
                    (
                    account_id int,	
                    princ_proc float,
                    inter_proc float,
                    misc_proc float							
                    )        
                
            INSERT INTO @Hedge_Cash_Trans_Base_Account
                (
                account_id,	
                princ_proc,
                inter_proc,
                misc_proc
                )
            --<-- APPDEV-3108> --Code End
            -- Adjust Cash Transaction to Original Hegde Account_id	
            SELECT 
                hpt.account_id,
                -SUM(hpt.principal_proceeds_amount) ,
                -SUM(hpt.interest_proceeds_amount) ,
                -SUM(hpt.misc_proceeds_amount) 
            FROM @hedge_pending_trades hpt
            Group by hpt.account_id
                    
            INSERT INTO @Hedge_Cash_Trans_Base_Account -- APPDEV-3108
                (
                account_id,	
                princ_proc,
                inter_proc,
                misc_proc
                )
            -- Adjust Converted Cash Transaction to matching Deal based Account_id	
            SELECT 
                hpt.deal_account_id,
                SUM(hpt.principal_proceeds_amount * hpt.spot_fx_rate),
                SUM(hpt.interest_proceeds_amount * hpt.spot_fx_rate),
                SUM(hpt.misc_proceeds_amount * hpt.spot_fx_rate)
            FROM @hedge_pending_trades hpt
            Group by hpt.deal_account_id

            -- APPDEV-3108
            DELETE FROM @Hedge_Cash_Trans_Base_Account
            WHERE account_id IN (SELECT t1.account_id FROM @Hedge_Cash_Trans t1 JOIN @Hedge_Cash_Trans_Base_Account t2
            ON t2.account_id=t1.account_id)

            -- Delte from the original account the hedges cash
            -- When an asset has a Hedge and you automatically add in the converted to the Base Currency account, 
            -- then you have effectively transferred those monies from the original account to the new account.  
            -- That asset will no longer impact the USD Currency Account.  The amount should remain the same as it was originally. 
            -- APPDEV- 3108
            DELETE FROM @Hedge_Cash_Trans_Base_Account
            WHERE account_id IN (SELECT DISTINCT t1.account_id FROM @hedge_pending_trades t1) 

            -- APPDEV-3108
            UPDATE t1 SET
                t1.princ_proc = t1.princ_proc + isnull(hct.princ_proc,0),
                t1.inter_proc = t1.inter_proc + isnull(hct.inter_proc,0),
                t1.misc_proc = t1.misc_proc + isnull(hct.misc_proc,0)
            FROM @t AS t1
            JOIN @Hedge_Cash_Trans_Base_Account AS hct 
                ON t1.account_id = hct.account_id
            --Code End 
            --APPDEV-3108
                    
        END
        -- SI 02/10/2015 (CDOSBAU-5886)
        --  Code END

        SELECT 
            @i = MIN(account_id) 
        FROM 
            @t

        WHILE @i IS NOT NULL BEGIN

            SELECT 
                @balances_string = isnull(@balances_string,'') + dbo.AccountBalanceString(account_id,princ_proc,inter_proc,misc_proc)  
            FROM 
                @t
            WHERE 
                account_id = @i

            SELECT 
                @i = MIN(account_id) 
            FROM 
                @t 
            WHERE 
                account_id > @i

        END

        IF @balances_string is not null BEGIN
            EXEC dbo.PS_Deal_Data_put 
                @ps_id = @ps_id, 
                @deal_data_type = 'CASH', 
                @deal_data_value = @balances_string, 
                @run_mode = 'GEN'
        END
        
    END
    /* </Adjust trade date cash using pending trade data> */


    EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - Insert Cash Into ps_deal_data'
	EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'Insert Cash Into ps_deal_data'

END

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_principal_reduction'
EXEC dbo.VRTS_PS_Generate_principal_reduction @ps_id = @ps_id, @begin_date = @transaction_begin, @regen_data = @regen_data
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_principal_reduction'

UPDATE dbo.ps_issue SET 
    issue_name = issue_facility_name 
FROM 
    ps_issue 
WHERE  
    issue_facility_name != issue_name AND 
    issue_type = 'L' AND
    issue_id > 0 AND
    ps_id = @ps_id


IF @regen_data != 1 BEGIN
	DECLARE @include_unfunded tinyint

	SET @include_unfunded = dbo.ConfigValue('PS_GEN_UC', @entity_id)

	IF ( @include_unfunded= 0) BEGIN

		DELETE FROM dbo.PS_Item WHERE issue_id < 0 AND ps_id = @ps_id

		DELETE FROM dbo.PS_ISSUE_CUSTOM WHERE ps_issue_id IN (SELECT ps_issue_id FROM PS_Issue WHERE issue_id < 0 AND ps_id = @ps_id)

		DELETE FROM dbo.PS_Issue_derivation_source WHERE ps_issue_id IN (SELECT ps_issue_id FROM PS_Issue WHERE issue_id < 0 AND ps_id = @ps_id)

		DELETE FROM dbo.PS_Issue WHERE issue_id < 0 AND ps_id = @ps_id

	END
END

-- Added by I.O. 02/02/2010 Start
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'if @entity_id = 84'
if @entity_id = 84 
    begin
        update a
            set defaulted = 1, 
                default_date = b.as_of_date,
                default_reason = case when default_reason is null then 'BNK' else default_reason end , 
                default_reason_desc = case when default_reason_desc is null then 'Bankruptcy' else default_reason_desc end
        from dbo.ps_issue a left join
            (select facility_id, max(as_of_date) as_of_date
                from dbo.Deal_facility_credit_opinion
                where entity_id = @entity_id and credit_opinion = 'D' and as_of_date <= @as_of_date
                group by facility_id
                ) b on a.facility_id = b.facility_id
        where a.ps_id = @ps_id and issue_type = 'L'
        and dbo.DealFacility_CreditOpinion(@entity_id, a.facility_id, @as_of_date) = 'D'

        update a
            set defaulted = 1, 
                default_date = b.as_of_date,
                default_reason = case when default_reason is null then 'BNK' else default_reason end , 
                default_reason_desc = case when default_reason_desc is null then 'Bankruptcy' else default_reason_desc end
        from dbo.ps_issue a left join
            (select issue_id, max(as_of_date) as_of_date
                from Deal_issue_credit_opinion
                where entity_id = @entity_id and credit_opinion = 'D' and as_of_date <= @as_of_date
                group by issue_id
                ) b on a.issue_id = b.issue_id
        where a.ps_id = @ps_id and issue_type <> 'L'
        and dbo.DealIssue_CreditOpinion(@entity_id, a.issue_id, @as_of_date) = 'D'


        insert into dbo.PS_Issue_Custom
            (
            ps_issue_id, 
            field_id, 
            field_value, 
            field_value_desc
            )
            select ps_issue_id, 10128, default_reason, default_reason_desc 
            from dbo.ps_issue
            where ps_id = @ps_id and issue_type = 'L'
                and dbo.DealFacility_CreditOpinion(@entity_id, facility_id, @as_of_date) = 'D'
                and ps_issue_id not in (select ps_issue_id from PS_Issue_Custom where field_id = 10128)

        insert into dbo.PS_Issue_Custom
            (
            ps_issue_id, 
            field_id, 
            field_value, 
            field_value_desc
            )
            select ps_issue_id, 10128, default_reason, default_reason_desc 
            from dbo.ps_issue
            where ps_id = @ps_id and issue_type <> 'L'
                and dbo.DealIssue_CreditOpinion(@entity_id, issue_id, @as_of_date) = 'D'
                and ps_issue_id not in (select ps_issue_id from PS_Issue_Custom where field_id = 10128)
    end
-- Added by I.O. 02/02/2010 End


IF @regen_data != 1 BEGIN
	EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'NEX_PS_note_interest'
	EXEC dbo.NEX_PS_note_interest @ps_id
	EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - NEX_PS_note_interest'
END

/* run rating derivation */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'PS_Issue_Rating_derive'
EXEC dbo.PS_Issue_Rating_derive	@ps_id= @ps_id, @run_mode = 'TOOL', @silent_mode = 1
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - PS_Issue_Rating_derive'

/* run recovery rate derivation */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'RRD_portfolio'
EXEC dbo.RRD_portfolio @ps_id = @ps_id, @run_mode = 'TOOL', @silent_mode = 1
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - RRD_portfolio'

IF @regen_data != 1 BEGIN
	/* Populate nex_ps_deal_hedge */
	EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_deal_hedge'
	EXEC dbo.VRTS_PS_Generate_deal_hedge @ps_id = @ps_id
	EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_deal_hedge'
END

/* Execute virtus principal balance rules */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Principal_Balance_generate'
EXEC dbo.VRTS_PS_Principal_Balance_generate @ps_id
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Principal_Balance_generate'

IF @regen_data != 1 BEGIN
	/* Delete positions based on threshold in deal settings and update Writen Down */
	EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_written_down'
	EXEC dbo.VRTS_PS_Generate_written_down @ps_id = @ps_id
	EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_written_down'
END

/* Prior Ratings */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'NEX_Prior_Ratings'
EXEC dbo.NEX_Prior_Ratings @entity_id, @ps_id
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - NEX_Prior_Ratings'

IF @regen_data != 1 BEGIN
	/* <Update issue_pik_factor> */
	UPDATE
		dbo.ps_issue 
	SET 
		issue_pik_factor = dbo.NEX_FacilityPIKFactorAsofDate(@entity_id, facility_id, @as_of_date, @date_basis, 0)
	where 
		ps_id = @ps_id
	and issue_type = 'L'
	/* </Update issue_pik_factor> */
END

/* <Regenerate principal balances based on the latest recovery rates>*/
DELETE
	pb
FROM
	dbo.ps_principal_balance pb
    JOIN dbo.ps_item i ON pb.ps_item_id = i.ps_item_id
WHERE ps_id =  @ps_id
AND pb_calc_method like 'BM%'

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'PS_Principal_Balance_generate'
EXEC dbo.PS_Principal_Balance_generate @ps_id = @ps_id;

/* </Regenerate principal balances based on the latest recovery rates>*/
IF @regen_data != 1 BEGIN
	/*<market value snapshot>*/
	IF @deal_type = 'MKT' BEGIN
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'virtus_market_value'
		EXEC virtus_market_value.dbo.mv_ps_generate @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - virtus_market_value'
	END
	/*</market value snapshot>*/

	/* Populate nex_ps_trs_accrual table */
	--IF @entity_id != 41 BEGIN
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_accrual'
		EXEC dbo.VRTS_PS_Generate_accrual @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_accrual'
	--END

	-- Added by I.O. 09/25/2009 Start
	if isnull(dbo.nex_getDealSetting(@entity_id, 'PS_INCLUDE_PROCESSED_PAYMENTS'),0) = 1 
		begin
			EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'vrts_ps_processed_but_not_received'
			exec dbo.vrts_ps_processed_but_not_received @ps_id, @entity_id, @as_of_date
			EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - vrts_ps_processed_but_not_received'
		end
	-- Added by I.O. 09/25/2009 End

	--Added BY SI 10/07/2016 -- APPDEV-1448
	DECLARE @period_code varchar(5)
	SELECT 
			@period_code = MAX(dbo.NEX_CT_ParameterValue_AsOfDate(@entity_id, deal_test_id, '@gain_loss_reporting_period',null,@as_of_date))
		FROM 
			dbo.deal_test 
		WHERE 
			test_id = 116 
			AND entity_id =  @entity_id
		
	IF @period_code IN( 'MTD','QTD','YTD') BEGIN
	--IF EXISTS (SELECT *	FROM dbo.deal_test 	WHERE test_id = 116 AND entity_id =  @entity_id) BEGIN
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_gain_loss_transactions'
		EXEC dbo.VRTS_PS_Generate_gain_loss_transactions @ps_id, @period_code
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_gain_loss_transactions'
	END

	-- Added BY SI 10/07/2016 -- APPDEV-1448

	/* <TRS Snapshot> */
	IF @deal_type = 'TRS' BEGIN
		-- <TRS-322>
		-- get the average swap base rate and recalculate the swap interest
		-- for libor_floor and non performing assets

		-- do this as the first item for TRS deal types so that accruals are updated
		-- before any other process access this information

		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_TRS_Recalc_Update_Swap_Interest'
		EXEC dbo.VRTS_PS_TRS_Recalc_Update_Swap_Interest @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_TRS_Recalc_Update_Swap_Interest'

		-- </TRS-322>

		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_cost_of_carry'
		EXEC dbo.VRTS_PS_Generate_TRS_cost_of_carry @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_cost_of_carry'
		
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_misc_fees'
		EXEC dbo.VRTS_PS_Generate_TRS_misc_fees @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_misc_fees'
		
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_ticking_fees'
		EXEC dbo.VRTS_PS_Generate_TRS_ticking_fees @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_ticking_fees'

		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_purchase_accrued_interest'
		EXEC dbo.VRTS_PS_Generate_TRS_purchase_accrued_interest @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_purchase_accrued_interest'
		
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_economic_benefit'
		EXEC dbo.VRTS_PS_Generate_TRS_economic_benefit @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_economic_benefit'
		
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_delayed_comp'
		EXEC dbo.VRTS_PS_Generate_TRS_delayed_comp @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_delayed_comp'

		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_fees'
		EXEC dbo.VRTS_PS_Generate_TRS_fees @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_fees'

		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_pending_trades'
		EXEC dbo.VRTS_PS_Generate_TRS_pending_trades @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_pending_trades'
		
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_minimum_utilization'
		EXEC dbo.VRTS_PS_Generate_TRS_minimum_utilization @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_minimum_utilization'

		IF @entity_id in(242, 142) BEGIN -- TJG Remove when Stephen is done testing.
			EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_TRS_Update_For_TRS_Multiplier'
			EXEC dbo.VRTS_PS_TRS_Update_For_TRS_Multiplier @ps_id = @ps_id
			EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_TRS_Update_For_TRS_Multiplier'
		END

		-- <TRS 373>
		-- should always be done as the last step
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Adjust_Synthetic_Accruals'
		EXEC dbo.VRTS_PS_Adjust_Synthetic_Accruals @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_minimum_utilization'
		-- </TRS 373>
	END
	/* </TRS Snapshot> */ 

	IF @deal_type != 'TRS' AND @vrts_ps_type IS NOT NULL BEGIN
		EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_TRS_pending_trades'
		EXEC dbo.VRTS_PS_Generate_TRS_pending_trades @ps_id = @ps_id
		EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_TRS_pending_trades'
	END

	/* Populate nex_ps_trade table */
	EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_trade'
	EXEC dbo.VRTS_PS_Generate_trade @ps_id = @ps_id
	EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_trade'
END

/* Populate nex_ps_rating_source */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'VRTS_PS_Generate_rating_source'
EXEC dbo.VRTS_PS_Generate_rating_source @ps_id
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - VRTS_PS_Generate_rating_source'

/*check to see if there are any deal variables that are required to run with the portfolio snapshot */
--EXEC NEX_Process_Snaphot_Variables @ps_id --</IO 12/19/2012 CDOSBAU-2701>
--EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - NEX_Process_Snaphot_Variables'--</IO 12/19/2012 CDOSBAU-2701>

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'CDOSBAU-2549'

IF @regen_data != 1 BEGIN
	--</IO 11/5/2012 CDOSBAU-2549 >
	update t
	set t.current_par_amount = -1 * t.current_par_amount,
		t.current_par_amount_deal_currency = -1 * t.current_par_amount_deal_currency,
		t.original_par_amount = -1 * t.original_par_amount
	from
	dbo.ps_issue i
	join dbo.ps_item t on i.ps_issue_id = t.ps_issue_id
	--left join ps_issue_custom c1 on c1.field_id = 10264 and i.ps_issue_id = c1.ps_issue_id   --Short_Position_UDF --(CDOSBAU-4793)
	left join dbo.ps_issue_custom c2 on c2.field_id = 10650 and i.ps_issue_id = c2.ps_issue_id	--FX_Pay_Leg_UDF
	where i.ps_id = @ps_id and 
	--(c1.field_value = '1' or (ltrim(rtrim(i.security_type)) = 'FXF' and c2.field_value = '1')) --(CDOSBAU-4793)
	(ISNULL(dbo.ItemCustomIdentifier(t.item_id,'Short_Position_UDF'),0) = '1' or (ltrim(rtrim(i.security_type)) = 'FXF' and c2.field_value = '1')) --(CDOSBAU-4793)

	--</IO 11/5/2012 CDOSBAU-2549 >


	-- <Virtus Change(CSAMRPTS-562)>
	UPDATE t
	SET
		t.par_commitment_traded = -1 * t.par_commitment_traded ,
		t.par_outstanding_traded = -1 *t.par_outstanding_traded, 
		t.par_commitment_settled = -1 * t.par_commitment_settled,
		t.par_outstanding_settled =	-1 * t.par_outstanding_settled

	FROM
	dbo.ps_issue i
	join dbo.ps_item t on i.ps_issue_id = t.ps_issue_id
	--left join ps_issue_custom c1 on c1.field_id = 10264 and i.ps_issue_id = c1.ps_issue_id   --Short_Position_UDF --(CDOSBAU-4793)
	left join dbo.ps_issue_custom c2 on c2.field_id = 10650 and i.ps_issue_id = c2.ps_issue_id	--FX_Pay_Leg_UDF
	WHERE i.ps_id = @ps_id and 
	(ISNULL(dbo.ItemCustomIdentifier(t.item_id,'Short_Position_UDF'),0) = '1' or (ltrim(rtrim(i.security_type)) = 'FXF' and c2.field_value = '1')) --(CDOSBAU-4793)

	-- </Virtus Change(CSAMRPTS-562)>

	--<WWU 4/10/2012 CDOSBAU-2039>
	-- update issue_current_par_amount,issue_original_face_amount,issue_principal_balance
	-- they are no longer computed columns
		update [dbo].[PS_Issue]
			set [issue_current_par_amount] = [dbo].[PS_IssueCurrentParAmount]([ps_id],[ps_issue_id]),
				[issue_original_face_amount] = [dbo].[PS_IssueOriginalFaceAmount]([ps_issue_id]),
				[issue_principal_balance] = [dbo].[PS_IssuePrincipalBalance]([ps_id],[ps_issue_id])
		where ps_id = @ps_id
	--</WWU 4/10/2012 CDOSBAU-2039>


	-- <CDOSBAU-5152> RA 7/18/2014

	DECLARE @price_type char(1)
	SELECT @price_type = CASE WHEN ISNULL(dbo.ConfigValue('use_effective_purchase_price', @entity_id), 0) = 1 THEN 'E' ELSE 'A' END

	IF @regen_data != 1 BEGIN
		UPDATE dbo.PS_Issue
		SET 
			WAPP_trd = 100.0 * dbo.vrts_WeightedAveragePurchasePrice(ISNULL(facility_id, issue_id), issue_type, @entity_id, @as_of_date, 'TRD', @price_type)
		WHERE
			ps_id = @ps_id
			AND WAPP_trd IS NULL
			
		UPDATE dbo.PS_Issue
		SET 
			WAPP_stld = 100.0 * dbo.vrts_WeightedAveragePurchasePrice(ISNULL(facility_id, issue_id), issue_type, @entity_id, @as_of_date, 'STLD', @price_type)
		WHERE 
			ps_id = @ps_id
			AND WAPP_stld IS NULL	
	END
		
	-- </CDOSBAU-5152>
END

-- <Virtus Change CDOSBAU-6994> RA 5/19/2015
UPDATE dbo.PS_Issue
SET 
	CSLLI_DM3_B = VirtusReporting.dbo.Benchmark_Static_gen_AsOfDate(21, 'DM 3-Year Life B', @as_of_date)
WHERE
	ps_id = @ps_id
	AND CSLLI_DM3_B IS NULL
	
UPDATE dbo.PS_Issue
SET 
	CSLLI_DM3_BB = VirtusReporting.dbo.Benchmark_Static_gen_AsOfDate(21, 'DM 3-Year Life BB', @as_of_date)
WHERE
	ps_id = @ps_id
	AND CSLLI_DM3_BB IS NULL
-- </Virtus Change CDOSBAU-6994>


--<IO 5/29/2015 CDOSBAU-7013>
UPDATE dbo.PS_Issue
SET 
	fitch_issuer_industry_description = dbo.VRTS_IndustryDescription(fitch_issuer_industry_id)
WHERE
	ps_id = @ps_id
	AND fitch_issuer_industry_description IS NULL			

UPDATE dbo.PS_Issue
SET 
	moody_issuer_industry_description = dbo.VRTS_IndustryDescription(moody_issuer_industry_id)
WHERE
	ps_id = @ps_id
	AND moody_issuer_industry_description IS NULL
	
UPDATE dbo.PS_Issue
SET 
	sp_issuer_industry_description = dbo.VRTS_IndustryDescription(dbo.IssuerIndustryId(dbo.PS_EntityId(@ps_id), issuer_id, 'SPR', as_of_date))
WHERE
	ps_id = @ps_id
	AND sp_issuer_industry_description IS NULL	
--</IO 5/29/2015 CDOSBAU-7013>

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'PS_Principal_Balance_generate'
EXEC dbo.PS_Principal_Balance_generate @ps_id = @ps_id;

/* </Regenerate principal balances based on the latest recovery rates>*/

-- <moved here> RA 9/25/2014 (CDOSBAU-5438) ------------------
--<WWU 4/10/2012 CDOSBAU-2039>
-- update issue_current_par_amount,issue_original_face_amount,issue_principal_balance
-- they are no longer computed columns
	update [dbo].[PS_Issue]
		set [issue_current_par_amount] = [dbo].[PS_IssueCurrentParAmount]([ps_id],[ps_issue_id]),
			[issue_original_face_amount] = [dbo].[PS_IssueOriginalFaceAmount]([ps_issue_id]),
			[issue_principal_balance] = [dbo].[PS_IssuePrincipalBalance]([ps_id],[ps_issue_id])
	where ps_id = @ps_id
--</WWU 4/10/2012 CDOSBAU-2039>
-- </moved here> RA 9/25/2014 (CDOSBAU-5438) ------------------

-- RA 9/22/2014 (CDOSBAU-5438)
-- must be called after principal balances are generated.
EXEC dbo.VRTS_PS_Calc_Principal_Balance_Exposure @ps_id = @ps_id;

IF @regen_data != 1 BEGIN
	EXEC dbo.NEX_PS_note_interest @ps_id  -- <IO 4/23/2012 CDOSBAU-2062   added this here>   
END

/*check to see if there are any deal variables that are required to run with the portfolio snapshot */
EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'NEX_Process_Snaphot_Variables'
EXEC dbo.NEX_Process_Snaphot_Variables @ps_id --</IO 12/19/2012 CDOSBAU-2701>
EXEC dbo.PS_Generation_summary_put	@sp_name = 'VRTS - NEX_Process_Snaphot_Variables' --</IO 12/19/2012 CDOSBAU-2701>

IF @regen_data != 1 BEGIN
	-- run the eligibility criteria test for the trades
	IF @vrts_ps_type = 'INIT' BEGIN
		EXEC VirtusTrade.dbo.PS_Run_Trade_EC @ps_id = @ps_id
	END
END

EXEC dbo.VRTS_trace_put @ps_id, 0, 'VRTS_PS_Generate_Extended', 'END'


go


USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[VRTS_Rpt_Cash_Flow_Payment_Monthly]    Script Date: 7/17/2019 10:58:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--http://cdosuite.virtusapp.local/Apps/VirtusReport/MIS_Reports/CashFlowPaymentMonthly/CashFlowPaymentMonthly.asp
-- EXEC VRTS_Rpt_Cash_Flow_Payment_Monthly @begin_date='2009-03-22', @entity_list='0;93;183;48;19;38;144;141;148;149;150;122;30;101;105;178;160;163;170;153;100;126;165;166;41;171;172;156;108;173;127;107;29;45;164;77;175;87;182;103;39;102;46;145;140;70;27;111;24;63;66;80;104;21;67;69;176;84;7;95;188;167;177;15;53;52;138;61;133;115;73;26;68;50;54;86;58;62;88;97;157;96;158;92;82;35;36;12;28;154;91;90;44;180;181;128;17;129;131;130;132;135;49;40;34;59;187;185;124;125;147;33;32;174;184;9;8;162;65;47;139;37;155;143;151;152;146;23;56;71;74;13;14;121;123;110;113;106;89;99;64;159;161;11;22;134;137;136;179;51;75;83;98;43;18;78;', @end_date='2009-03-25', @report_type='PR', @user_id='tpercival', @status='O', @time_range='B' 

--grant exec on VRTS_Rpt_Cash_Flow_Payment_Monthly to cdo_suite_full 
						
ALTER PROCEDURE [dbo].[VRTS_Rpt_Cash_Flow_Payment_Monthly]
/*******************************************************************
* PURPOSE: Returns a list of transactions for applying cash receipts
* NOTES: 
* CREATED: 5/12/2006 by Wayne Schwartz
* MODIFIED 
* DATE			AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
* 07/03/2019	YR			IE-1863 Adding columns to the MR and PR report result set
* 07/15/2019	YR			IE-1879 changing @entity_list and @deal_type to varchar(max)
* 07/17/2019	YR			IE-1868	Adding VRTS TRS snapshot details along with the the portfolio details
* 07/18/2019	YR			IE-1868	Adding new weekly report schedule for TRS
*******************************************************************/
@user_id user_id,
@entity_list varchar(max) = NULL,	-- IE-1879
@begin_date datetime = NULL,
@end_date datetime = '2070-01-01 23:59:59:999',
@report_type varchar(4) = NULL,
@status varchar(4) = NULL,
@time_range varchar(4),
@deal_type varchar(max) = NULL,		-- IE-1879
@excel bit = 0,
@recordset_number int = NULL,
@vpnexus bit = 0

AS
SET NOCOUNT ON

IF @begin_date IS NULL BEGIN
	SET @begin_date = '1900-01-01'
END

IF @end_date IS NULL BEGIN
	SET @end_date = '2070-01-01 23:59:59:999' 
END ELSE BEGIN
	SET @end_date = dbo.EndOfDay(@end_date)
END

/*<Deal Type>*/
DECLARE @deal_types TABLE
	(
	deal_type varchar(4)
	)

IF @deal_type IS NOT NULL BEGIN
	INSERT INTO @deal_types
		(
		deal_type
		)
		SELECT
			record_string deal_type
		FROM
			dbo.tf_split(@deal_type, ';')

END 
/*</Deal Type>*/

/*<Report Type>*/
DECLARE @report_type_desc varchar(30)

SET @report_type_desc = 
	CASE @report_type
		WHEN 'MR' THEN 'Monthly Report'
		WHEN 'PR' THEN 'Payment Report'
		WHEN 'CF' THEN 'Cash Flow'
	END
/*</Report Type>*/


DECLARE @entity TABLE (
	entity_id int, 
	deal_name varchar(50), 
	deal_type varchar(10),
	cashflow_due_time datetime,
	cashflow_same_day tinyint)

IF RTRIM(@entity_list) = '' BEGIN
	SET @entity_list = NULL
END

IF @entity_list IS NOT NULL BEGIN
	INSERT INTO @entity 
		(
		entity_id, 
		deal_name,
		deal_type,
		cashflow_due_time,
		cashflow_same_day
		)
	SELECT 
		ent.entity_id, 
		ent.deal_name,
		ent.deal_type,
		dbo.ConfigValue('cashflow_due_time', ent.entity_id) cashflow_due_time,
		dbo.ConfigValue('cashflow_same_day', ent.entity_id) cashflow_same_day
	FROM 
		dbo.Entity ent
		JOIN 
			(	
			SELECT 
				entity_id = record_string
			FROM 
				dbo.tf_split(@entity_list, ';')
			) ent_limiter ON ent.entity_id = ent_limiter.entity_id
		LEFT JOIN @deal_types dt ON ent.deal_type = dt.deal_type 
		LEFT JOIN NEX_Entity ne on ent.entity_id = ne.entity_id		
	WHERE
		(
			@deal_type IS NULL OR
			dt.deal_type IS NOT NULL
		)
		AND dbo.cdosa_DealAccess(@user_id, ent.entity_id) >= 0

END ELSE BEGIN 

	INSERT INTO @entity 
		(
		entity_id, 
		deal_name,
		deal_type,
		cashflow_due_time,
		cashflow_same_day
		)
	SELECT 
		ent.entity_id, 
		ent.deal_name,
		ent.deal_type,
		dbo.ConfigValue('cashflow_due_time', ent.entity_id) cashflow_due_time,
		dbo.ConfigValue('cashflow_same_day', ent.entity_id) cashflow_same_day
	FROM 
		dbo.Entity ent
		LEFT JOIN @deal_types dt ON ent.deal_type = dt.deal_type 
		LEFT JOIN NEX_Entity ne on ent.entity_id = ne.entity_id				
	WHERE
		(
			@deal_type IS NULL OR
			dt.deal_type IS NOT NULL
		)
		AND	ISNULL(ent.actual_term_dt, @end_date) >= @end_date
		AND dbo.cdosa_DealAccess(@user_id, ent.entity_id) >= 0
END

if @report_type != 'CF' BEGIN

	/*<Payment Schedule>*/
	DECLARE @Payment_Schedule TABLE(
		entity_id int,
		determination_date datetime,
		due_date datetime
	)

	INSERT @Payment_Schedule 
	SELECT dps.entity_id, dps.determination_date, ndps.due_date 
	FROM deal_payment_schedule dps 
		LEFT JOIN nex_deal_payment_schedule_extended ndps ON dps.deal_payment_id = ndps.deal_payment_id
		JOIN @entity e ON dps.entity_id = e.entity_id
	WHERE
		determination_date between @begin_date and @end_date
	/*</Payment Schedule>*/

	IF @report_type = 'MR' BEGIN
		/*<Monthly Schedule>*/
		DECLARE @Monthly_Schedule TABLE(
		entity_id int,
		report_date datetime,
		due_date datetime
		)

		INSERT @Monthly_Schedule 
		SELECT drs.entity_id, drs.report_date, drs.due_date
		FROM vrts_deal_report_schedule drs 
			LEFT JOIN @Payment_Schedule ps ON drs.entity_id = ps.entity_id AND (YEAR(report_date) = YEAR(determination_date) AND MONTH(report_date) = MONTH(determination_date))
			JOIN @entity e ON drs.entity_id = e.entity_id
		/*</Monthly Schedule>*/
	END

	-- IE-1868

	if @report_type = 'WK'
	begin
		declare @weekly_schedule table (entity_id int,
			as_of_date datetime,
			due_date datetime)

		insert into @weekly_schedule (entity_id,
			as_of_date)
		select p.entity_id,
			max(p.end_date)
		from dbo.VRTS_TPS_Portfolio_Snapshot p
		join @entity e ON p.entity_id = e.entity_id
		left join dbo.VRTS_TPS_Portfolio_Snapshot_Classification psc ON p.tps_id = psc.tps_id
		where psc.classification_code = 'WK'
		group by p.entity_id

		declare @next_day_id int  = 0 -- 0 = Mon, 1 = Tue, 2 = Wed, ..., 5 = Sat, 6 = Sun
		declare @due_date datetime
		declare @as_of_date datetime
		declare @entity_id int

		declare @deal_jurisdiction table (item_category varchar(50),
			jurisdiction_code varchar(50),
			jurisdiction_code_1 varchar(50),
			jurisdiction_name varchar(255))

		declare @jurisdiction_code_string varchar(8000)

		declare @business_date table (actual_date datetime,
			is_business_date bit,
			holiday_comments varchar(255),
			adjusted_business_date datetime)

		select @entity_id = min(entity_id)
		from @weekly_schedule

		while @entity_id is not null
		begin
			delete from @deal_jurisdiction
			delete from @business_date
			select @jurisdiction_code_string = null

			select @as_of_date = as_of_date
			from @weekly_schedule
			where entity_id = @entity_id

			select @due_date = dateadd(day, (datediff(day, @next_day_id, @as_of_date) / 7) * 7 + 7, @next_day_id)

			insert into @deal_jurisdiction
			exec dbo.Deal_jurisdiction_list @entity_id = @entity_id

			select @jurisdiction_code_string = coalesce(@jurisdiction_code_string + ', ', '') + jurisdiction_code
			from @deal_jurisdiction

			insert into @business_date
			exec dbo.Date_Business_Date_check @actual_date = @due_date, @jurisdiction_codes_string = @jurisdiction_code_string

			select @due_date = adjusted_business_date
			from @business_date

			update @weekly_schedule
			set due_date = @due_date
			where entity_id = @entity_id

			select @entity_id = min(entity_id)
			from @weekly_schedule
			where entity_id > @entity_id
		end
	end

	-- IE-1863
END

IF @report_type = 'CF' BEGIN

	IF @excel = 1 BEGIN
		SELECT  
			'Report Info' recordset_header,
			deal_name = @report_type_desc + ' - ' + CONVERT(varchar(10), @begin_date , 101) + ' to ' + CONVERT(varchar(10), @end_date , 101) ,
			title = 'As Of ' + CONVERT(varchar(10),getdate() , 101)
	END

	IF isnull(@recordset_number,1) = 1 OR @excel = 1 BEGIN
		SELECT 
			_header = 'Cash Flow Status', 
			"Deal Name" = dbo.dealname(v.entity_id),
			"Description" = v.description, 
			"Date Created" = v.created_date,
			"Time Created" = CONVERT(varchar,v.created_date,108),
			"Created By" = dbo.UserName(v.created_by),
			Status = 
--				CASE e.deal_type
--					WHEN 'TRS' THEN
--						case when v.created_date > v.end_date + '1/1/1900 14:30' then 'Past Due' else 'On or Before Due Time' end
--					ELSE 
						Case 
							When e.cashflow_same_day != 1  or e.cashflow_same_day is null Then 
								--case when v.created_date > CASE WHEN datepart(weekday,v.end_date) = 6 THEN dateadd(day, 3, v.end_date) ELSE dateadd(day, 1, v.end_date) END + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
								case when v.created_date > dbo.businessDateAdd(e.entity_id, 1, v.end_date) + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
							Else
								case when v.created_date > v.end_date + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
						End,
--				END,	
			"Deal type" = e.deal_type,
			"Classification" = dbo.CodeDesc('CS_CLASSIFICATION',v.classification_code),
			"Past Due Reason Category" = dbo.CodeDesc('CS_PASTDUE_REASON',v.pastdue_reason_category),
			"Past Due Reason Comments" = dbo.CodeDesc('CS_PASTDUE_COMMENTS',v.pastdue_reason_comment),
			Comments = v.comments

		FROM 
			dbo.VRTS_CS_Cash_Snapshot v JOIN @entity e ON v.entity_id = e.entity_id
		WHERE 
--			((deal_type = 'trs' AND classification_code = 'trs') OR (deal_type != 'trs' AND classification_code = 'apr'))
			((classification_code = dbo.ConfigValue('cf_nexus_approval_category',v.entity_id)) and (classification_code <> 'NA'))

--			AND created_date >= @begin_date and created_date < dateadd(day, 1, @end_date)
			AND end_date >= @begin_date and end_date < dateadd(day, 1, @end_date)

			AND ((@time_range = 'B' AND
						Case 
							When e.cashflow_same_day != 1 or e.cashflow_same_day is null Then 
								--case when v.created_date > CASE WHEN datepart(weekday,v.end_date) = 6 THEN dateadd(day, 3, v.end_date) ELSE dateadd(day, 1, v.end_date) END + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
								case when v.created_date > dbo.businessDateAdd(e.entity_id, 1, v.end_date) + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
							
							Else
								case when v.created_date > v.end_date + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
						End = 'Past Due')
				OR
				(@time_range = 'C' AND convert(datetime,CONVERT(varchar,v.created_date,108)) < '1/1/1900 14:30')
				OR 
				 @time_range = 'A')
			AND
				(
					(
						@vpnexus = 0
					) 
					OR 
					(
						@vpnexus = 1 
						AND
--						CASE e.deal_type
--							WHEN 'TRS' THEN
--								case when convert(datetime,CONVERT(varchar,v.created_date,108)) > '1/1/1900 15:00' then 'Past Due' else 'On or Before Due Time' end
--							ELSE 
--								case when convert(datetime,CONVERT(varchar,v.created_date,108)) > '1/1/1900 10:30' then 'Past Due' else 'On or Before Due Time' end
--						END = 'Past Due'
						Case 
							When e.cashflow_same_day != 1  or e.cashflow_same_day is null Then 
								--case when v.created_date > CASE WHEN datepart(weekday,v.end_date) = 6 THEN dateadd(day, 3, v.end_date) ELSE dateadd(day, 1, v.end_date) END + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
								case when v.created_date > dbo.businessDateAdd(e.entity_id, 1, v.end_date) + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
							Else
								case when v.created_date > v.end_date + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
						END = 'Past Due'

					)
				)
			AND
				(
					(
						@status ='A'
					)
					OR
					(
						@status = 'P'
						AND
--						CASE e.deal_type
--							WHEN 'TRS' THEN
--								case when v.created_date > v.end_date + '1/1/1900 14:30' then 'Past Due' else 'On or Before Due Time' end
--							ELSE 
								Case 
									When e.cashflow_same_day != 1 or e.cashflow_same_day is null Then 
										--case when v.created_date > CASE WHEN datepart(weekday,v.end_date) = 6 THEN dateadd(day, 3, v.end_date) ELSE dateadd(day, 1, v.end_date) END + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
										case when v.created_date > dbo.businessDateAdd(e.entity_id, 1, v.end_date) + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
							
									Else
										case when v.created_date > v.end_date + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
								End = 'Past Due'
--						END = 'Past Due'
					)
					OR
					(
						@status = 'O'
						AND
--						CASE e.deal_type
--							WHEN 'TRS' THEN
--								case when v.created_date > v.end_date + '1/1/1900 14:30' then 'Past Due' else 'On or Before Due Time' end
--							ELSE 
								Case 
									When e.cashflow_same_day != 1 or e.cashflow_same_day is null Then 
										--case when v.created_date > CASE WHEN datepart(weekday,v.end_date) = 6 THEN dateadd(day, 3, v.end_date) ELSE dateadd(day, 1, v.end_date) END + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
										case when v.created_date > dbo.businessDateAdd(e.entity_id, 1, v.end_date) + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
							
									Else
										case when v.created_date > v.end_date + isnull(e.cashflow_due_time, '1/1/1900 10:00') then 'Past Due' else 'On or Before Due Time' end
								End = 'On or Before Due Time'
--						END = 'On or Before Due Time'
					)

				)
		ORDER BY 
			dbo.dealname(v.entity_id),
			created_date DESC,
			description
	END

	IF @recordset_number = 3 OR @excel = 1 BEGIN

		DECLARE @Dates TABLE (date datetime, entity_id int)
		DECLARE @date datetime

		SET @date = @begin_date

		WHILE @date <= @end_date BEGIN

			IF DATEPART(weekday, @date) not in (1,7) BEGIN
				INSERT @Dates VALUES (@date, null)
			END

			SET @date = dateadd(day, 1, @date)

		END

		INSERT @Dates 
		SELECT d.date, e.entity_id
		FROM @Dates d, @entity e

		DELETE FROM @Dates
		WHERE entity_id is null

		DECLARE @Exceptions TABLE  (Sheet_Name varchar(200), Deal_Name varchar(200), Date datetime)
/*select * from @dates
SELECT
	e.entity_id,
	date = convert(datetime,CONVERT(varchar,v.end_date,101)) 
FROM 
	dbo.VRTS_CS_Cash_Snapshot v JOIN @entity e ON v.entity_id = e.entity_id
*/		INSERT @Exceptions
		SELECT 
			sheet_name = 'Exceptions',
			Deal_Name = dbo.dealname(d.entity_id),
			d.Date
		FROM 
			@Dates d LEFT JOIN 
			(
				SELECT
					e.entity_id,
					date = convert(datetime,CONVERT(varchar,v.end_date,101)) 
				FROM 
					dbo.VRTS_CS_Cash_Snapshot v JOIN @entity e ON v.entity_id = e.entity_id
				WHERE 
--					((deal_type = 'trs' AND classification_code = 'trs') OR (deal_type != 'trs' AND classification_code = 'apr'))
					((classification_code = dbo.ConfigValue('cf_nexus_approval_category',v.entity_id)) and (classification_code <> 'NA'))

/*					AND created_date >= @begin_date and end_date < dateadd(day, 1, @end_date)

					AND ((@time_range = 'B' AND convert(datetime,CONVERT(varchar,v.created_date,108)) <= '1/1/1900 10:00')
						OR
						(@time_range = 'C' AND convert(datetime,CONVERT(varchar,v.created_date,108)) < '1/1/1900 14:30')
						OR 
						 @time_range = 'A')
					AND
						(
							(
								@vpnexus = 0
							) 
							OR 
							(
								@vpnexus = 1 
								AND
								CASE e.deal_type
									WHEN 'TRS' THEN
										case when convert(datetime,CONVERT(varchar,v.end_date,108)) > '1/1/1900 15:00' then 'Past Due' else 'On or Before Due Time' end
									ELSE 
										case when convert(datetime,CONVERT(varchar,v.end_date,108)) > '1/1/1900 10:30' then 'Past Due' else 'On or Before Due Time' end
								END = 'Past Due'
							)
						)
*/
			) tmp ON d.date = tmp.date and d.entity_id = tmp.entity_id
		WHERE 
			tmp.date is null
		ORDER BY 
			dbo.dealname(d.entity_id),
			d.Date DESC

		IF @excel = 1 BEGIN
			Select sheet_name, "Deal Name" = deal_name, Date from @Exceptions
		END ELSE BEGIN
			Select "Deal Name" = deal_name, Date From @Exceptions
		END

	END

END ELSE IF @report_type in ('MR','PR', 'WK') BEGIN

	IF @excel = 1 BEGIN
		SELECT  
			'Report Info' recordset_header,
			deal_name = @report_type_desc + ' - ' + CONVERT(varchar(10), @begin_date , 101) + ' to ' + CONVERT(varchar(10), @end_date , 101) ,
			title = 'As Of ' + CONVERT(varchar(10),getdate() , 101)
	END

	IF @recordset_number = 1 OR @excel = 1 BEGIN
		SELECT		
			header_ =  dbo.nex_getSnapshotClassification(p.ps_id, 'desc'),
			"Deal Name" = dbo.dealname(p.entity_id),
			"Deal Type" = e.deal_type,
			"Description" = ISNULL(p.ps_description, dbo.PS_DefaultDesc(p.ps_id)), 
			"As Of Date" = p.as_of_date,
			"Date Created" = CONVERT(varchar, p.create_date, 101),
			"Time Created" = CONVERT(varchar,p.create_date,108),
			"Due Date" = 
				CASE 
					WHEN @report_type = 'MR' THEN ms.due_date 
					WHEN @report_type = 'PR' THEN ps.due_date 
				END,
			"Created By" = dbo.UserName(p.created_by),
			Status = 
				CASE 
					WHEN @report_type = 'MR' AND convert(datetime,convert(varchar,p.create_date,101)) > ms.due_date THEN 'Past Due' 	
					WHEN @report_type = 'PR' AND convert(datetime,convert(varchar,p.create_date,101)) > ps.due_date THEN 'Past Due' 
				END,		
			"Snapshot Classification" = dbo.nex_getSnapshotClassification(p.ps_id, 'desc'),
			p.Comments,
			-- IE-1863
			"Director" = (select agent_name from (select agent_name, row_number() over (partition by entity_id,agent_type order by deal_agent_id desc) rank
				from [dbo].[vrts_Deal_agent] vda where vda.agent_type = 'VCM' and vda.entity_id = e.entity_id) a where rank = 1),
			"Approval Date" = nsc.last_update_date,
			"Past Due Reason" = nsc.past_due_reason,
			"Past Due Comment" = nsc.past_due_comment,
			"Draft Versions" = nsc.draft_versions_sent_to_client,
			"Date of First Report" = nsc.date_first_draft_sent_to_client
			-- IE-1863
		FROM 
			dbo.PS_Portfolio_Snapshot p
			JOIN @entity e ON p.entity_id = e.entity_id
			LEFT JOIN NEX_Snapshot_Classification nsc on nsc.ps_id = p.ps_id	-- IE-1863
			LEFT JOIN @Monthly_Schedule ms ON ms.entity_id = p.entity_id AND ms.report_date = p.as_of_date
			LEFT JOIN @Payment_Schedule ps ON ps.entity_id = p.entity_id AND ps.determination_date = p.as_of_date
		WHERE 
			((@report_type = 'PR' AND dbo.nex_getSnapshotClassification(p.ps_id, 'code') = 'PR')
			OR
			(@report_type = 'MR' AND dbo.nex_getSnapshotClassification(p.ps_id, 'code') = 'MR'))
			
			AND

			CASE 
				WHEN @report_type = 'MR' THEN ms.due_date 
				WHEN @report_type = 'PR' THEN ps.due_date 
			END is not null 
			
			AND

			(
				(
					@vpnexus = 0
				) 
				OR
				(
					CASE 
						WHEN @report_type = 'MR' AND convert(datetime,convert(varchar,p.create_date,101)) > ms.due_date THEN 'Past Due' 	
						WHEN @report_type = 'PR' AND convert(datetime,convert(varchar,p.create_date,101)) > ps.due_date THEN 'Past Due' 
					END = 'Past Due'
				)
			)
			and p.create_date between @begin_date and @end_date

			-- IE-1868
		UNION ALL
		select 
			header_ =  dbo.nex_getSnapshotClassification(p.tps_id, 'desc'),
			"Deal Name" = dbo.dealname(p.entity_id),
			"Deal Type" = e.deal_type,
			"Description" = ISNULL(p.tps_description, 'TPS'), 
			"As Of Date" = p.end_date,
			"Date Created" = CONVERT(varchar, p.create_date, 101),
			"Time Created" = CONVERT(varchar,p.create_date,108),
			"Due Date" = 
				CASE 
					WHEN @report_type = 'MR' THEN ms.due_date 
					WHEN @report_type = 'PR' THEN ps.due_date 
					WHEN @report_type = 'WK' THEN ws.due_date	-- IE-1868
				END,
			"Created By" = dbo.UserName(p.created_by),
			Status =
				CASE 
					WHEN @report_type = 'MR' AND convert(datetime,convert(varchar,p.create_date,101)) > ms.due_date THEN 'Past Due' 	
					WHEN @report_type = 'PR' AND convert(datetime,convert(varchar,p.create_date,101)) > ps.due_date THEN 'Past Due' 
					WHEN @report_type = 'WK' AND convert(datetime,convert(varchar,p.create_date,101)) > ws.due_date THEN 'Past Due'		-- IE-1868
				END,		
			"Snapshot Classification" = dbo.nex_getSnapshotClassification(p.tps_id, 'desc'),
			'',
			-- IE-1863
			"Director" = (select agent_name from (select agent_name, row_number() over (partition by entity_id,agent_type order by deal_agent_id desc) rank
				from [dbo].[vrts_Deal_agent] vda where vda.agent_type = 'VCM' and vda.entity_id = e.entity_id) a where rank = 1),
			"Approval Date" = psc.last_update_date,
			"Past Due Reason" = psc.past_due_reason,
			"Past Due Comment" = psc.past_due_comment,
			"Draft Versions" = psc.draft_versions_sent_to_client,
			"Date of First Report" = psc.date_first_draft_sent_to_client
			-- IE-1863
		FROM
			dbo.VRTS_TPS_Portfolio_Snapshot p
			JOIN @entity e ON p.entity_id = e.entity_id
			LEFT JOIN dbo.VRTS_TPS_Portfolio_Snapshot_Classification psc ON p.tps_id = psc.tps_id
			LEFT JOIN @Monthly_Schedule ms ON ms.entity_id = p.entity_id AND ms.report_date = p.end_date
			LEFT JOIN @Payment_Schedule ps ON ps.entity_id = p.entity_id AND ps.determination_date = p.end_date
			LEFT JOIN @weekly_schedule ws on ws.entity_id = p.entity_id AND ws.as_of_date = p.end_date
		WHERE 
			((@report_type = 'PR' AND dbo.VRTS_TPS_getSnapshotClassification(p.tps_id, 'code') = 'PR')
			OR
			(@report_type = 'MR' AND dbo.VRTS_TPS_getSnapshotClassification(p.tps_id, 'code') = 'MR')
			OR
			(@report_type = 'WK' AND dbo.VRTS_TPS_getSnapshotClassification(p.tps_id, 'code') = 'WK'))	-- IE-1868
			
			AND

			CASE 
				WHEN @report_type = 'MR' THEN ms.due_date 
				WHEN @report_type = 'PR' THEN ps.due_date 
				WHEN @report_type = 'WK' THEN ws.due_date	-- IE-1868
			END is not null 
			
			AND

			(
				(
					@vpnexus = 0
				) 
				OR
				(
					CASE 
						WHEN @report_type = 'MR' AND convert(datetime,convert(varchar,p.create_date,101)) > ms.due_date THEN 'Past Due' 	
						WHEN @report_type = 'PR' AND convert(datetime,convert(varchar,p.create_date,101)) > ps.due_date THEN 'Past Due' 
						WHEN @report_type = 'WK' AND convert(datetime,convert(varchar,p.create_date,101)) > ws.due_date THEN 'Past Due'	-- IE-1868
					END = 'Past Due'
				)
			)
			and p.create_date between @begin_date and @end_date
	END

	
	IF @recordset_number = 3 OR @excel = 1 BEGIN
		SELECT		
			header_ = dbo.nex_getSnapshotClassification(p.ps_id, 'desc') + ' Exceptions',
			"Deal Name" = dbo.dealname(p.entity_id),
			"Deal Type" = e.deal_type,
			"Description" = ISNULL(p.ps_description, dbo.PS_DefaultDesc(p.ps_id)), 
			"As Of Date" = p.as_of_date,
			"Date Created" = p.create_date,
			"Time Created" = CONVERT(varchar,p.create_date,108),
			"Due Date" = 
				CASE 
					WHEN @report_type = 'MR' THEN ms.due_date 
					WHEN @report_type = 'PR' THEN ps.due_date 
				END,

			"Created By" = dbo.UserName(p.created_by),
			Status = 
				CASE 
					WHEN @report_type = 'MR' AND convert(datetime,convert(varchar,p.create_date,101)) > ms.due_date THEN 'Past Due' 	
					WHEN @report_type = 'PR' AND convert(datetime,convert(varchar,p.create_date,101)) > ps.due_date THEN 'Past Due' 
				END,		
			"Snapshot Classification" = dbo.nex_getSnapshotClassification(p.ps_id, 'desc'),
			p.Comments,
			-- IE-1863
			"Director" = (select agent_name from (select agent_name, row_number() over (partition by entity_id,agent_type order by deal_agent_id desc) rank
				from [dbo].[vrts_Deal_agent] vda where vda.agent_type = 'VCM' and vda.entity_id = e.entity_id) a where rank = 1),
			"Approval Date" = nsc.last_update_date,
			"Past Due Reason" = nsc.past_due_reason,
			"Past Due Comment" = nsc.past_due_comment,
			"Draft Versions" = nsc.draft_versions_sent_to_client,
			"Date of First Report" = nsc.date_first_draft_sent_to_client
			-- IE-1863
		FROM 
			dbo.PS_Portfolio_Snapshot p 
			JOIN @entity e ON p.entity_id = e.entity_id
			LEFT JOIN NEX_Snapshot_Classification nsc on nsc.ps_id = p.ps_id	-- IE-1863
			LEFT JOIN @Monthly_Schedule ms ON ms.entity_id = p.entity_id AND ms.report_date = p.as_of_date
			LEFT JOIN @Payment_Schedule ps ON ps.entity_id = p.entity_id AND ps.determination_date = p.as_of_date
		WHERE 
			((@report_type = 'PR' AND dbo.nex_getSnapshotClassification(p.ps_id, 'code') = 'PR')
			OR
			(@report_type = 'MR' AND dbo.nex_getSnapshotClassification(p.ps_id, 'code') = 'MR'))

			AND 

			CASE 
				WHEN @report_type = 'MR' THEN ms.due_date 
				WHEN @report_type = 'PR' THEN ps.due_date 
			END is null 

			AND

			(
				(
					@vpnexus = 0
				) 
				OR 
				(
					CASE 
						WHEN @report_type = 'MR' AND convert(datetime,convert(varchar,p.create_date,101)) > ms.due_date THEN 'Past Due' 	
						WHEN @report_type = 'PR' AND convert(datetime,convert(varchar,p.create_date,101)) > ps.due_date THEN 'Past Due' 
					END = 'Past Due'
				)
			)
			and p.create_date between @begin_date and @end_date
		-- IE-1868
		UNION ALL
		select 
			header_ =  dbo.nex_getSnapshotClassification(p.tps_id, 'desc'),
			"Deal Name" = dbo.dealname(p.entity_id),
			"Deal Type" = e.deal_type,
			"Description" = ISNULL(p.tps_description, 'TPS'), 
			"As Of Date" = p.end_date,
			"Date Created" = CONVERT(varchar, p.create_date, 101),
			"Time Created" = CONVERT(varchar,p.create_date,108),
			"Due Date" = 
				CASE 
					WHEN @report_type = 'MR' THEN ms.due_date 
					WHEN @report_type = 'PR' THEN ps.due_date 
					WHEN @report_type = 'WK' THEN ws.due_date	-- IE-1868
				END,
			"Created By" = dbo.UserName(p.created_by),
			Status =
				CASE 
					WHEN @report_type = 'MR' AND convert(datetime,convert(varchar,p.create_date,101)) > ms.due_date THEN 'Past Due' 	
					WHEN @report_type = 'PR' AND convert(datetime,convert(varchar,p.create_date,101)) > ps.due_date THEN 'Past Due' 
					WHEN @report_type = 'WK' AND convert(datetime,convert(varchar,p.create_date,101)) > ws.due_date THEN 'Past Due'		-- IE-1868
				END,		
			"Snapshot Classification" = dbo.nex_getSnapshotClassification(p.tps_id, 'desc'),
			'',
			-- IE-1863
			"Director" = (select agent_name from (select agent_name, row_number() over (partition by entity_id,agent_type order by deal_agent_id desc) rank
				from [dbo].[vrts_Deal_agent] vda where vda.agent_type = 'VCM' and vda.entity_id = e.entity_id) a where rank = 1),
			"Approval Date" = psc.last_update_date,
			"Past Due Reason" = psc.past_due_reason,
			"Past Due Comment" = psc.past_due_comment,
			"Draft Versions" = psc.draft_versions_sent_to_client,
			"Date of First Report" = psc.date_first_draft_sent_to_client
			-- IE-1863
		FROM
			dbo.VRTS_TPS_Portfolio_Snapshot p
			JOIN @entity e ON p.entity_id = e.entity_id
			LEFT JOIN dbo.VRTS_TPS_Portfolio_Snapshot_Classification psc ON p.tps_id = psc.tps_id
			LEFT JOIN @Monthly_Schedule ms ON ms.entity_id = p.entity_id AND ms.report_date = p.end_date
			LEFT JOIN @Payment_Schedule ps ON ps.entity_id = p.entity_id AND ps.determination_date = p.end_date
			LEFT JOIN @weekly_schedule ws on ws.entity_id = p.entity_id AND ws.as_of_date = p.end_date
		WHERE 
			((@report_type = 'PR' AND dbo.VRTS_TPS_getSnapshotClassification(p.tps_id, 'code') = 'PR')
			OR
			(@report_type = 'MR' AND dbo.VRTS_TPS_getSnapshotClassification(p.tps_id, 'code') = 'MR')
			OR
			(@report_type = 'WK' AND dbo.VRTS_TPS_getSnapshotClassification(p.tps_id, 'code') = 'WK'))	-- IE-1868
			
			AND

			CASE 
				WHEN @report_type = 'MR' THEN ms.due_date 
				WHEN @report_type = 'PR' THEN ps.due_date 
				WHEN @report_type = 'WK' THEN ws.due_date	-- IE-1868
			END is not null 
			
			AND

			(
				(
					@vpnexus = 0
				) 
				OR
				(
					CASE 
						WHEN @report_type = 'MR' AND convert(datetime,convert(varchar,p.create_date,101)) > ms.due_date THEN 'Past Due' 	
						WHEN @report_type = 'PR' AND convert(datetime,convert(varchar,p.create_date,101)) > ps.due_date THEN 'Past Due' 
						WHEN @report_type = 'WK' AND convert(datetime,convert(varchar,p.create_date,101)) > ws.due_date THEN 'Past Due'	-- IE-1868
					END = 'Past Due'
				)
			)
			and p.create_date between @begin_date and @end_date
	END

END


go

USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[VRTS_TPS_Portfolio_Snapshot_Classification_get]    Script Date: 6/18/2019 11:22:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[VRTS_TPS_Portfolio_Snapshot_Classification_get]

/*******************************************************************
* PROCEDURE: VRTS_TPS_Portfolio_Snapshot_Classification_get
* PURPOSE: Adds data to VRTS_TPS_Portfolio_Snapshot_Classification
* NOTES: COPIED FROM NEX_Snapshot_classification_get
* CREATED: 01/07/2012 By TLe
* Sample Run: VRTS_TPS_Portfolio_Snapshot_Classification_get 96708
* MODIFIED 
* DATE			AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
* 06/19/2019	YR			IE-1835 Add more columns for the table VRTS_TPS_Portfolio_Snapshot_Classification
*******************************************************************/

@tps_id int

AS
BEGIN

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

	declare @entity_id int
	declare @as_of_date datetime
	declare @mr_due_date datetime
	declare @pr_due_date datetime

	select @entity_id = entity_id,
		@as_of_date = end_date
	from VRTS_TPS_Portfolio_Snapshot
	where tps_id = @tps_id

	select @mr_due_date = due_date
	from vrts_deal_report_schedule
	where entity_id = @entity_id
		and report_date = @as_of_date

	select @pr_due_date = ndps.due_date
	from Deal_Payment_Schedule dps
	left join dbo.NEX_Deal_Payment_Schedule_extended ndps ON dps.deal_payment_id = ndps.deal_payment_id
	where entity_id = @entity_id
		and determination_date = @as_of_date

	SELECT
		tps_id, 
		ltrim(rtrim(classification_code)) as 'classification_code',
		tps_Classification_id,
		past_due_reason,	-- IE-1835
		past_due_comment,	-- IE-1835
		draft_versions_sent_to_client,	-- IE-1835
		date_first_draft_sent_to_client,	-- IE-1835
		@entity_id as 'entity_id',	-- IE-1835
		@as_of_date as 'as_of_date',	-- IE-1835
		isnull(@mr_due_date, '1/1/1900') as 'mr_due_date',	-- IE-1835
		isnull(@pr_due_date, '1/1/1900') as 'pr_due_date',	-- IE-1835
		last_update_date as 'last_update_date'				-- IE-1835
	FROM VRTS_TPS_Portfolio_Snapshot_Classification
	WHERE tps_id = @tps_id

END

go

USE [cdo_suite_6]
GO
/****** Object:  StoredProcedure [dbo].[VRTS_TPS_Portfolio_Snapshot_Classification_put]    Script Date: 6/18/2019 11:19:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[VRTS_TPS_Portfolio_Snapshot_Classification_put]
/*******************************************************************
* PROCEDURE: VRTS_TPS_Portfolio_Snapshot_Classification_put
* PURPOSE: Adds data to VRTS_TPS_Portfolio_Snapshot_Classification
* NOTES: COPIED FROM dbo.NEX_Snapshot_classification_put 
* CREATED: 01/07/2012 By TLe
* Sample Run: VRTS_TPS_Portfolio_Snapshot_Classification_put 96708, 3, 'LA'
* MODIFIED 
* DATE		AUTHOR		DESCRIPTION
*-------------------------------------------------------------------
* 03/20/12	TLe			Modified to add @silent_mode to generate daily reports
*						for new TRS snapshot TRS-696
* 06/18/19	YR			IE-1835 Add more columns for the table VRTS_TPS_Portfolio_Snapshot_Classification
*******************************************************************/

	@tps_id int ,
	@tps_Classification_id int = NULL,
	@classification_code char(4) = NULL,
	@user_id user_id = NULL,
	@silent_mode bit = 0,
	@past_due_reason		varchar(500) = null,
	@past_due_comment		varchar(500) = null,
	@draft_versions_sent_to_client int = null,
	@date_first_draft_sent_to_client datetime = null,
	@entity_id				int = null,
	@as_of_date				datetime = null,
	@mr_due_date			datetime = null,
	@pr_due_date			datetime = null
AS
BEGIN

SET NOCOUNT ON

DECLARE @operation_result_code int,
	@operation_message_code varchar(50),
	@action_message_code varchar(50),
	@operation_details varchar(1000)

SET @operation_result_code = @@ERROR

		IF ISNULL(@tps_Classification_id, 0) = 0
			BEGIN
				INSERT dbo.VRTS_TPS_Portfolio_Snapshot_Classification
					(
					tps_id,
					classification_code,
					created_by, 
					create_date,
					last_updated_by,
					last_update_date,
					past_due_reason,	-- IE-1835
					past_due_comment,	-- IE-1835
					draft_versions_sent_to_client,	-- IE-1835
					date_first_draft_sent_to_client	-- IE-1835
					)
				VALUES
					(
					@tps_id,
					ISNULL(@classification_code,'NA'),
					@user_id,					
					getdate(),
					@user_id,
					getdate(),
					@past_due_reason,	-- IE-1835
					@past_due_comment,	-- IE-1835
					@draft_versions_sent_to_client,	-- IE-1835
					@date_first_draft_sent_to_client	-- IE-1835
					)

				SELECT @tps_Classification_id = SCOPE_IDENTITY()
			
			END			
		ELSE
			BEGIN
				UPDATE dbo.VRTS_TPS_Portfolio_Snapshot_Classification
				SET
					classification_code = @classification_code,		
					last_updated_by = @user_id, 
					last_update_date = getdate(),
					past_due_reason = @past_due_reason,	-- IE-1835
					past_due_comment = @past_due_comment,	-- IE-1835
					draft_versions_sent_to_client = @draft_versions_sent_to_client,	-- IE-1835
					date_first_draft_sent_to_client = @date_first_draft_sent_to_client	-- IE-1835
				WHERE
					tps_Classification_id = @tps_Classification_id
			END
/* RETURN MESSAGES TO FRONT END WHEN @silent_mode = 0*/
IF @silent_mode = 0 
BEGIN
	SELECT
		operation_primary_key = 'TPS_ID;' + CAST(@tps_id AS varchar),
		*
	FROM tf_OperationMessage (@operation_result_code, @operation_message_code, @action_message_code, @operation_details)
END

END

go

