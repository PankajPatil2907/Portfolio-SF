public with sharing class OpportunityDealAnalyzerAction {

    public class Request {
        @InvocableVariable(
            label='Opportunity Name or ID' 
            description='The Salesforce ID (15 or 18 characters) or the Name of the Opportunity to analyze.' 
            required=true
        )
        public String opportunityId;

        @InvocableVariable(
            label='User Question' 
            description='Question or guidance requested by the sales representative' 
            required=false
        )
        public String userQuestion;
    }

    public class Response {
        @InvocableVariable(
            label='Analysis Result' 
            description='Formatted deal analysis and recommendations from the LLM prompt template'
        )
        public String analysisResult;

        @InvocableVariable(
            label='Is Success' 
            description='Indicates whether the prompt execution succeeded'
        )
        public Boolean isSuccess;

        @InvocableVariable(
            label='Error Message' 
            description='Details of any error that occurred during execution'
        )
        public String errorMessage;
    }

    /**
     * @description Invocable method called by Agentforce subagents or topics to analyze an Opportunity.
     * Supports looking up Opportunities by Salesforce ID or Opportunity Name.
     */
    @InvocableMethod(
        label='Analyze Opportunity Deal' 
        description='Analyzes Opportunity and Account data via the Opportunity Deal Analyzer prompt template using either Opportunity Name or ID.'
        category='Salesforce Agentforce Deals'
    )
    public static List<Response> analyzeDeal(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        final String PROMPT_TEMPLATE_NAME = 'Opportunity_Deal_Analyzer';

        for (Request req : requests) {
            Response res = new Response();

            try {
                String searchInput = String.isNotBlank(req.opportunityId) ? req.opportunityId.trim() : '';
                if (String.isBlank(searchInput)) {
                    throw new IllegalArgumentException('Please provide an Opportunity Name or ID to perform deal analysis.');
                }

                // 1. Resolve Opportunity by ID or Name
                Opportunity opp = findOpportunity(searchInput);
                if (opp == null) {
                    res.isSuccess = false;
                    res.errorMessage = 'No Opportunity found matching "' + searchInput + '".';
                    res.analysisResult = 'Information not available: Unable to find an Opportunity matching "' + searchInput + '". Please verify the Opportunity Name or provide the Opportunity ID.';
                    responses.add(res);
                    continue;
                }

                String userQuery = String.isNotBlank(req.userQuestion) 
                    ? req.userQuestion 
                    : 'What is the current deal status, what information is missing, what are the potential risks, and what should be my immediate next action?';

                // 2. Prepare comprehensive ground context for LLM
                String enrichedContext = 
                    '=== OPPORTUNITY DETAILS ===\n' +
                    '- Opportunity Name: ' + opp.Name + '\n' +
                    '- Stage: ' + opp.StageName + '\n' +
                    '- Amount: ' + (opp.Amount != null ? ('$' + String.valueOf(opp.Amount)) : 'Information not available.') + '\n' +
                    '- Close Date: ' + (opp.CloseDate != null ? String.valueOf(opp.CloseDate) : 'Information not available.') + '\n' +
                    '- Probability: ' + (opp.Probability != null ? (String.valueOf(opp.Probability) + '%') : 'Information not available.') + '\n' +
                    '- Type: ' + (String.isNotBlank(opp.Type) ? opp.Type : 'Information not available.') + '\n' +
                    '- Lead Source: ' + (String.isNotBlank(opp.LeadSource) ? opp.LeadSource : 'Information not available.') + '\n' +
                    '- Next Step: ' + (String.isNotBlank(opp.NextStep) ? opp.NextStep : 'Information not available.') + '\n' +
                    '- Description: ' + (String.isNotBlank(opp.Description) ? opp.Description : 'Information not available.') + '\n\n' +
                    '=== ACCOUNT DETAILS ===\n' +
                    '- Account Name: ' + (opp.Account != null && String.isNotBlank(opp.Account.Name) ? opp.Account.Name : 'Information not available.') + '\n' +
                    '- Industry: ' + (opp.Account != null && String.isNotBlank(opp.Account.Industry) ? opp.Account.Industry : 'Information not available.') + '\n' +
                    '- Annual Revenue: ' + (opp.Account != null && opp.Account.AnnualRevenue != null ? ('$' + String.valueOf(opp.Account.AnnualRevenue)) : 'Information not available.') + '\n' +
                    '- Employees: ' + (opp.Account != null && opp.Account.NumberOfEmployees != null ? String.valueOf(opp.Account.NumberOfEmployees) : 'Information not available.') + '\n' +
                    '- Account Type: ' + (opp.Account != null && String.isNotBlank(opp.Account.Type) ? opp.Account.Type : 'Information not available.') + '\n\n' +
                    '=== SALES REPRESENTATIVE QUESTION ===\n' +
                    userQuery;

                // 3. Build input parameters map for Prompt Template
                Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();

                // Input: Opportunity (record ID wrapper)
                Map<String, String> oppDataMap = new Map<String, String>{ 'id' => opp.Id };
                ConnectApi.WrappedValue oppValue = new ConnectApi.WrappedValue();
                oppValue.value = oppDataMap;
                inputParams.put('Input:Opportunity', oppValue);

                // Input: Account (record ID wrapper)
                if (opp.AccountId != null) {
                    Map<String, String> accDataMap = new Map<String, String>{ 'id' => opp.AccountId };
                    ConnectApi.WrappedValue accValue = new ConnectApi.WrappedValue();
                    accValue.value = accDataMap;
                    inputParams.put('Input:Account', accValue);
                }

                // Input: User_Question (grounded context + rep question)
                ConnectApi.WrappedValue questionValue = new ConnectApi.WrappedValue();
                questionValue.value = enrichedContext;
                inputParams.put('Input:User_Question', questionValue);

                // 4. Configure ConnectApi Prompt Template Input
                ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
                promptInput.inputParams = inputParams;
                promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
                promptInput.additionalConfig.applicationName = 'PromptBuilderPreview';
                promptInput.isPreview = false;

                // 5. Invoke LLM via ConnectApi
                ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationOutput;
                if (!Test.isRunningTest()) {
                    generationOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(PROMPT_TEMPLATE_NAME, promptInput);
                } else {
                    generationOutput = getMockTestResponse();
                }

                // 6. Parse response
                if (generationOutput != null && generationOutput.generations != null && !generationOutput.generations.isEmpty()) {
                    res.analysisResult = generationOutput.generations[0].text;
                    res.isSuccess = true;
                } else {
                    res.isSuccess = false;
                    res.errorMessage = 'Prompt template generated an empty response.';
                    res.analysisResult = 'Information not available: Unable to generate deal analysis.';
                }

            } catch (Exception ex) {
                res.isSuccess = false;
                res.errorMessage = ex.getMessage();
                res.analysisResult = 'Error analyzing opportunity: ' + ex.getMessage();
            }

            responses.add(res);
        }

        return responses;
    }

    /**
     * @description Helper to look up an Opportunity by 15/18 char ID or Name (exact and fuzzy).
     */
    private static Opportunity findOpportunity(String searchInput) {
        // Check if input is a valid 15 or 18 character Salesforce ID
        if (searchInput.length() == 15 || searchInput.length() == 18) {
            try {
                Id parsedId = (Id)searchInput;
                if (parsedId.getSObjectType() == Opportunity.SObjectType) {
                    List<Opportunity> byId = [
                        SELECT Id, Name, StageName, Amount, CloseDate, Probability, 
                               Type, LeadSource, NextStep, Description,
                               AccountId, Account.Name, Account.Industry, Account.AnnualRevenue,
                               Account.NumberOfEmployees, Account.Type, Account.Description
                        FROM Opportunity 
                        WHERE Id = :parsedId 
                        LIMIT 1
                    ];
                    if (!byId.isEmpty()) {
                        return byId[0];
                    }
                }
            } catch (Exception ignored) {
                // Not an ID, proceed to Name search
            }
        }

        // Search by exact Name
        List<Opportunity> byName = [
            SELECT Id, Name, StageName, Amount, CloseDate, Probability, 
                   Type, LeadSource, NextStep, Description,
                   AccountId, Account.Name, Account.Industry, Account.AnnualRevenue,
                   Account.NumberOfEmployees, Account.Type, Account.Description
            FROM Opportunity 
            WHERE Name = :searchInput 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        if (!byName.isEmpty()) {
            return byName[0];
        }

        // Search by fuzzy Name (LIKE)
        String fuzzyQuery = '%' + searchInput + '%';
        List<Opportunity> byFuzzyName = [
            SELECT Id, Name, StageName, Amount, CloseDate, Probability, 
                   Type, LeadSource, NextStep, Description,
                   AccountId, Account.Name, Account.Industry, Account.AnnualRevenue,
                   Account.NumberOfEmployees, Account.Type, Account.Description
            FROM Opportunity 
            WHERE Name LIKE :fuzzyQuery 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        if (!byFuzzyName.isEmpty()) {
            return byFuzzyName[0];
        }

        return null;
    }

    /**
     * @description Provides mock response for unit tests
     */
    @TestVisible
    private static ConnectApi.EinsteinPromptTemplateGenerationsRepresentation getMockTestResponse() {
        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation mockOutput = 
            new ConnectApi.EinsteinPromptTemplateGenerationsRepresentation();
        
        ConnectApi.EinsteinLLMGenerationItemOutput genItem = new ConnectApi.EinsteinLLMGenerationItemOutput();
        genItem.text = 'Opportunity Summary: Deal evaluated.\n' +
                       'Current Deal Status: In progress.\n' +
                       'Missing Information: None.\n' +
                       'Potential Risks: Low.\n' +
                       'Recommended Next Actions: Follow up.\n' +
                       'Answer to Sales Representative: The deal is active.';
        
        mockOutput.generations = new List<ConnectApi.EinsteinLLMGenerationItemOutput>{ genItem };
        return mockOutput;
    }
}