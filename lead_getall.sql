USE [TheNext90_RoarTracker]
GO

/****** Object:  StoredProcedure [dbo].[Lead_GetAll]    Script Date: 12/1/2024 8:19:20 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







-- =============================================
-- Author:		Zeeshan Hanif
-- Create date: 04/10/2013
-- Description:	Get all leads
-- =============================================
-- Lead_GetAll 100,0,null,'',null,null,null,1,null,null,null,1,null
CREATE PROCEDURE [dbo].[Lead_GetAll]
(
	@MaximumRows AS INT,
	@StartRowIndex AS INT,
	@SortParameter AS VARCHAR(30) = NULL,
	@Search AS VARCHAR(20) = NULL,
	@SubscribeDateFrom AS VARCHAR(20) = NULL,
	@SubscribeDateTo AS VARCHAR(20) = NULL,	
	@IsClient AS BIT = NULL,
	@UserId AS INT,
	@ContactMethod AS VARCHAR(100)=NULL,
	@ContactStatus AS VARCHAR(100)=NULL,
	@OpportunityResult AS VARCHAR(100)=NULL,
	@IsTeamDashboard AS BIT,
	@AssignedTo AS VARCHAR(100)=NULL
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 IF(IsNULL(@AssignedTo, '') = '')
	 BEGIN
		SET @AssignedTo = @UserId
	 END
	
	IF(@IsTeamDashboard = 1)
	 BEGIN
	--	WITH Tree AS 
	--( 	
	--	SELECT Id
	--	FROM [User] 
	--	WHERE Id = @UserId
		
	--	UNION ALL
		
	--	SELECT ct.Id
	--	FROM [User] ct
	--	INNER JOIN Tree ON Tree.Id = ct.ManagerId
	--	AND ct.IsDeleted = 0 
	--),
	
	;with tblLeads AS(
	SELECT ROW_NUMBER() OVER (	
			ORDER BY 
				(CASE WHEN @SortParameter is NULL OR @SortParameter = '' THEN Lead.[ContractStartDate] END) DESC, 
				
				(CASE WHEN @SortParameter = 'FirstName' THEN Lead.FirstName END) ASC,
				(CASE WHEN @SortParameter = 'FirstName DESC' THEN Lead.FirstName END) DESC,
				
				(CASE WHEN @SortParameter = 'LastName' THEN Lead.LastName END) ASC,
				(CASE WHEN @SortParameter = 'LastName DESC' THEN Lead.LastName END) DESC,
				
				(CASE WHEN @SortParameter = 'Company' THEN Company END) ASC,
				(CASE WHEN @SortParameter = 'Company DESC' THEN Company END) DESC,
				
				(CASE WHEN @SortParameter = 'Email' THEN Email END) ASC,
				(CASE WHEN @SortParameter = 'Email DESC' THEN Email END) DESC,
				
				(CASE WHEN @SortParameter = 'WorkPhone' THEN Lead.WorkPhone END) ASC,
				(CASE WHEN @SortParameter = 'WorkPhone DESC' THEN Lead.WorkPhone END) DESC,
				
				(CASE WHEN @SortParameter = 'ContactStatus' THEN ContactStatus END) ASC,
				(CASE WHEN @SortParameter = 'ContactStatus DESC' THEN ContactStatus END) DESC,
				
				(CASE WHEN @SortParameter = 'ContactMethod' THEN ContactMethod END) ASC,
				(CASE WHEN @SortParameter = 'ContactMethod DESC' THEN ContactMethod END) DESC,
				
				(CASE WHEN @SortParameter = 'OpportunityResult' THEN OpportunityResults END) ASC,
				(CASE WHEN @SortParameter = 'OpportunityResult DESC' THEN OpportunityResults END) DESC,
				
				(CASE WHEN @SortParameter = 'SubscribedOn' THEN SubscribedOn END) ASC,
				(CASE WHEN @SortParameter = 'SubscribedOn DESC' THEN SubscribedOn END) DESC,

				(CASE WHEN @SortParameter = 'ManagerName' THEN ManagerName END) ASC,
				(CASE WHEN @SortParameter = 'ManagerName DESC' THEN ManagerName END) DESC,


					(CASE WHEN @SortParameter = 'Coach' THEN Coach END) ASC,
				(CASE WHEN @SortParameter = 'Coach DESC' THEN Coach END) DESC,
					(CASE WHEN @SortParameter = 'ContractStartDate' THEN ContractStartDate END) ASC,
				(CASE WHEN @SortParameter = 'ContractStartDate DESC' THEN ContractStartDate END) DESC,
				(CASE WHEN @SortParameter = 'Notes' THEN Notes END) ASC,
				(CASE WHEN @SortParameter = 'Notes DESC' THEN Notes END) DESC,
				Lead.[ContractStartDate] DESC
									 
	) AS RowIndex,* FROM (SELECT
	   [Lead].[Id]
      ,[IsClient]
      ,Lead.[FirstName]
      ,Lead.[LastName]
      ,[Company]
      ,[Lead].[Title]
      ,ContactDetail.[Email]
      ,ContactDetail.[Phone]
      ,ContactDetail.[WorkPhone]
      ,ContactDetail.[CellPhone]
      ,ContactDetail.[Fax]      
      ,ContactDetail.[Address1]
      ,ContactDetail.[Address2]
      ,ContactDetail.[City]
      ,ContactDetail.[State]
      ,ContactDetail.[Zip]
      ,[LeadOwnerUserId]
      ,[USER].FirstName +' '+[USER].LastName AS LeadOwnerName
      ,[SubscribedOn]
      ,ISNULL([tblContactStatus].[Title],'N/A') AS ContactStatusTitle
      ,ContactStatus
      ,ISNULL([tblContactMethod].[Title],'N/A') AS ContactMethodTitle
      ,ContactMethod
      ,ISNULL([tblOpportunityResult].[Title],'N/A') AS OpportunityResultTitle
      ,OpportunityResults
      ,dbo.GetLeadCommentsupdated(Lead.Id) as comment
      ,[Profile]      
      ,Lead.[IsDeleted]
	  ,Lead.ModifiedOn
      ,dbo.GetActionsCountByLeadId(@UserId,Lead.Id,1) ActionDue
	   ,[ContractPrice]
	   ,[ManagerName]
	   ,[Events]
	   ,[ContractStartDate]
	   ,[ContractEndDate]
	   ,[Split]
	   ,[Coach]
	   ,[Client]
	   ,[BranchSplit]
	   ,[ClientSplit]
	   ,[CorporateSplit]
	   ,[Commission]
 
	     ,Lead.Notes
  FROM [Lead] WITH(NOLOCK)
  LEFT OUTER JOIN ContactDetail ON ContactDetail.LeadId = [Lead].Id
  LEFT OUTER JOIN ContactScheme AS tblContactMethod ON [Lead].[ContactMethod] = tblContactMethod.[Id]
  LEFT OUTER JOIN ContactScheme AS tblContactStatus ON [Lead].[ContactStatus] = tblContactStatus.[Id]
  LEFT OUTER JOIN ContactScheme AS tblOpportunityResult ON [Lead].[OpportunityResults] = tblOpportunityResult.[Id]
  INNER JOIN [User] ON [USER].Id=Lead.LeadOwnerUserId
  WHERE Lead.IsDeleted = 0  
	AND (@IsClient IS NULL OR IsClient = @IsClient)
	AND (IsNULL(@ContactMethod, '') = '' OR PATINDEX('%,' + CAST(tblContactMethod.Id as varchar(15)) + ',%', ','+ @ContactMethod +',')>0)
	--AND (@ContactMethod=0 OR tblContactMethod.Id = @ContactMethod)
	AND (IsNULL(@ContactStatus, '') = '' OR PATINDEX('%,' + CAST(tblContactStatus.Id as varchar(15)) + ',%', ','+ @ContactStatus +',')>0)
	--AND (@ContactStatus =0 OR tblContactStatus.Id = @ContactStatus)
	AND (IsNULL(@OpportunityResult, '') = '' OR PATINDEX('%,' + CAST(tblOpportunityResult.Id as varchar(15)) + ',%', ','+ @OpportunityResult +',')>0)
	--AND (@OpportunityResult=0 OR tblOpportunityResult.Id = @OpportunityResult)
	AND (ISNULL(@SubscribeDateFrom, '') = '' or  CAST(SubscribedOn as DATE) >= CAST(@SubscribeDateFrom AS DATE))
	AND (ISNULL(@SubscribeDateTo, '') = '' or  CAST(SubscribedOn as DATE) <= CAST(@SubscribeDateTo AS DATE))
	AND (@Search = '' 
		OR Lead.FirstName LIKE '%'+ @Search +'%' 
		OR Lead.LastName LIKE '%'+ @Search +'%' 
		OR ContactDetail.Email LIKE '%'+ @Search +'%' 
		OR Company LIKE '%'+ @Search +'%'
		 OR ContactDetail.City LIKE '%'+ @Search +'%'
		OR ContactDetail.State  LIKE '%'+ @Search +'%' 
		 OR 
		 Lead.Coach Like '%'+ @Search +'%' 
		)  
  AND [Lead].LeadOwnerUserId IN(SELECT @UserId  UNION SELECT Id From [User] Where ManagerId = @UserId)
  AND (IsNULL(@AssignedTo, '') ='' OR PATINDEX('%,' + CAST([Lead].LeadOwnerUserId as varchar(15)) + ',%', ','+ @AssignedTo +',')>0)
  )Lead)
		
  
  SELECT *
  FROM tblLeads
  --LEFT JOIN Tree ON Tree.Id = tblLeads.LeadOwnerUserId
  WHERE RowIndex BETWEEN @StartRowIndex AND (@StartRowIndex + @MaximumRows) - 1  
  
	 END
	ELSE
	 BEGIN	
 
	  ;WITH tblLeads AS(
	SELECT ROW_NUMBER() OVER (	
			ORDER BY 
				(CASE WHEN @SortParameter is NULL OR @SortParameter = '' THEN Lead.[ContractStartDate] END) DESC, 
				
				(CASE WHEN @SortParameter = 'FirstName' THEN Lead.FirstName END) ASC,
				(CASE WHEN @SortParameter = 'FirstName DESC' THEN Lead.FirstName END) DESC,
				
				(CASE WHEN @SortParameter = 'LastName' THEN Lead.LastName END) ASC,
				(CASE WHEN @SortParameter = 'LastName DESC' THEN Lead.LastName END) DESC,
				
				(CASE WHEN @SortParameter = 'Company' THEN Company END) ASC,
				(CASE WHEN @SortParameter = 'Company DESC' THEN Company END) DESC,
				
				(CASE WHEN @SortParameter = 'Email' THEN Email END) ASC,
				(CASE WHEN @SortParameter = 'Email DESC' THEN Email END) DESC,
				
				(CASE WHEN @SortParameter = 'WorkPhone' THEN Lead.WorkPhone END) ASC,
				(CASE WHEN @SortParameter = 'WorkPhone DESC' THEN Lead.WorkPhone END) DESC,
				
				(CASE WHEN @SortParameter = 'ContactStatus' THEN ContactStatus END) ASC,
				(CASE WHEN @SortParameter = 'ContactStatus DESC' THEN ContactStatus END) DESC,
				
				(CASE WHEN @SortParameter = 'ContactMethod' THEN ContactMethod END) ASC,
				(CASE WHEN @SortParameter = 'ContactMethod DESC' THEN ContactMethod END) DESC,
				
				(CASE WHEN @SortParameter = 'OpportunityResult' THEN OpportunityResults END) ASC,
				(CASE WHEN @SortParameter = 'OpportunityResult DESC' THEN OpportunityResults END) DESC,
				
				(CASE WHEN @SortParameter = 'SubscribedOn' THEN SubscribedOn END) ASC,
				(CASE WHEN @SortParameter = 'SubscribedOn DESC' THEN SubscribedOn END) DESC,

				(CASE WHEN @SortParameter = 'ManagerName' THEN ManagerName END) ASC,
				(CASE WHEN @SortParameter = 'ManagerName DESC' THEN  ManagerName END) DESC,

					(CASE WHEN @SortParameter = 'Coach' THEN Coach END) ASC,
				(CASE WHEN @SortParameter = 'Coach DESC' THEN Coach END) DESC,
					(CASE WHEN @SortParameter = 'ContractStartDate' THEN ContractStartDate END) ASC,
				(CASE WHEN @SortParameter = 'ContractStartDate DESC' THEN ContractStartDate END) DESC,
					(CASE WHEN @SortParameter = 'Notes' THEN Notes END) ASC,
				(CASE WHEN @SortParameter = 'Notes DESC' THEN Notes END) DESC,
				Lead.[ContractStartDate] DESC
									 
	) AS RowIndex, * FROM (SELECT 
	   [Lead].[Id]
      ,[IsClient]
      ,Lead.[FirstName]
      ,Lead.[LastName]
      ,[Company]
      ,[Lead].[Title]
      ,ContactDetail.[Email]
      ,ContactDetail.[Phone]
      ,ContactDetail.[WorkPhone]
      ,ContactDetail.[CellPhone]
      ,ContactDetail.[Fax]      
      ,ContactDetail.[Address1]
      ,ContactDetail.[Address2]
      ,ContactDetail.[City]
      ,ContactDetail.[State]
      ,ContactDetail.[Zip]
      ,[LeadOwnerUserId]
      ,[User].FirstName +' ' +[User].LastName AS LeadOwnerName
      ,[SubscribedOn]
      ,ISNULL([tblContactStatus].[Title],'N/A') AS ContactStatusTitle
      ,ContactStatus
      ,ISNULL([tblContactMethod].[Title],'N/A') AS ContactMethodTitle
      ,ContactMethod
      ,ISNULL([tblOpportunityResult].[Title],'N/A') AS OpportunityResultTitle
      ,OpportunityResults
      ,dbo.GetLeadCommentsupdated(Lead.Id) as comment
      ,[Profile]      
	  ,Lead.ModifiedOn
      ,Lead.[IsDeleted]
      ,dbo.GetActionsCountByLeadId(@UserId,Lead.Id,1) ActionDue
	   ,Lead.[ContractPrice]
	   ,Lead.[ManagerName]
	   ,Lead.[Events]
	   ,Lead.[ContractStartDate]
	   ,Lead.[ContractEndDate]
	   ,Lead.[Split]
	   ,Lead.[Coach]
	   ,Lead.[Client]
	   ,Lead.[BranchSplit]
	   ,Lead.[ClientSplit]
	   ,Lead.[CorporateSplit]
	   ,Lead.[Commission]
	 
	     ,Lead.Notes
  FROM [Lead] WITH(NOLOCK)
  LEFT OUTER JOIN ContactDetail ON ContactDetail.LeadId = [Lead].Id
  LEFT OUTER JOIN ContactScheme AS tblContactMethod ON [Lead].[ContactMethod] = tblContactMethod.[Id]
  LEFT OUTER JOIN ContactScheme AS tblContactStatus ON [Lead].[ContactStatus] = tblContactStatus.[Id]
  LEFT OUTER JOIN ContactScheme AS tblOpportunityResult ON [Lead].[OpportunityResults] = tblOpportunityResult.[Id]
  LEFT OUTER JOIN [User] ON [USER].Id=Lead.LeadOwnerUserId
  WHERE Lead.IsDeleted = 0  
	AND (@IsClient IS NULL OR IsClient = @IsClient)
	AND (IsNULL(@ContactMethod, '') = '' OR PATINDEX('%,' + CAST([Lead].[ContactMethod] as varchar(15)) + ',%', ','+ @ContactMethod +',')>0)
	--AND (@ContactMethod=0 OR tblContactMethod.Id = @ContactMethod)
	AND (IsNULL(@ContactStatus, '') = '' OR PATINDEX('%,' + CAST([Lead].[ContactStatus] as varchar(15)) + ',%', ','+ @ContactStatus +',')>0)
	--AND (@ContactStatus =0 OR tblContactStatus.Id = @ContactStatus)
	AND (IsNULL(@OpportunityResult, '') = '' OR PATINDEX('%,' + CAST([Lead].[OpportunityResults] as varchar(15)) + ',%', ','+ @OpportunityResult +',')>0)
	--AND (@OpportunityResult=0 OR tblOpportunityResult.Id = @OpportunityResult)
  AND (@Search = '' 
		OR Lead.FirstName LIKE '%'+ @Search +'%' 
		OR Lead.LastName LIKE '%'+ @Search +'%' 
		OR ContactDetail.Email LIKE '%'+ @Search +'%' 
		OR Company LIKE '%'+ @Search +'%'
		 OR ContactDetail.City LIKE '%'+ @Search +'%'
		OR ContactDetail.State  LIKE '%'+ @Search +'%' 
		 OR  
			
			Lead.Coach Like '%'+ @Search +'%' 
		)
  --AND [Lead].LeadOwnerUserId IN(SELECT @UserId  UNION SELECT Id From [User] Where ManagerId = @UserId AND IsDeleted = 0)
  AND (IsNULL(@AssignedTo, '') ='' OR [Lead].LeadOwnerUserId IN (SELECT NUMBER FROM dbo.ListToTable(@AssignedTo) WHERE number > 0))
		AND (ISNULL(@SubscribeDateFrom, '') = '' or  CAST(SubscribedOn as DATE) >= CAST(@SubscribeDateFrom AS DATE))
		AND (ISNULL(@SubscribeDateTo, '') = '' or  CAST(SubscribedOn as DATE) <= CAST(@SubscribeDateTo AS DATE))
  )Lead)
  
  
  SELECT *
  FROM tblLeads
  WHERE RowIndex BETWEEN @StartRowIndex AND (@StartRowIndex + @MaximumRows) - 1
  --ORDER BY tblLeads.ModifiedOn DESC
	 END
END

GO


