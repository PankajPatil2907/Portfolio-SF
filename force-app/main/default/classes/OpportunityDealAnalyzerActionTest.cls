@IsTest
private class OpportunityDealAnalyzerActionTest {

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(
            Name = 'Acme Test Corp',
            Industry = 'Technology'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'Acme Cloud Test Opp',
            StageName = 'Proposal/Price Quote',
            Amount = 100000,
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    }

    @IsTest
    static void testAnalyzeDealSuccessById() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityDealAnalyzerAction.Request req = new OpportunityDealAnalyzerAction.Request();
        req.opportunityId = opp.Id;
        req.userQuestion = 'What are the main risks with this deal?';

        Test.startTest();
        List<OpportunityDealAnalyzerAction.Response> responses = 
            OpportunityDealAnalyzerAction.analyzeDeal(new List<OpportunityDealAnalyzerAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isTrue(responses[0].isSuccess, 'Execution should be successful');
        Assert.isNotNull(responses[0].analysisResult, 'Result should not be null');
    }

    @IsTest
    static void testAnalyzeDealSuccessByName() {
        OpportunityDealAnalyzerAction.Request req = new OpportunityDealAnalyzerAction.Request();
        req.opportunityId = 'Acme Cloud Test Opp'; // Search by Name!
        req.userQuestion = 'Give me deal details.';

        Test.startTest();
        List<OpportunityDealAnalyzerAction.Response> responses = 
            OpportunityDealAnalyzerAction.analyzeDeal(new List<OpportunityDealAnalyzerAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isTrue(responses[0].isSuccess, 'Execution should be successful using Opportunity Name');
    }

    @IsTest
    static void testAnalyzeDealFuzzyName() {
        OpportunityDealAnalyzerAction.Request req = new OpportunityDealAnalyzerAction.Request();
        req.opportunityId = 'Acme Cloud'; // Fuzzy name match!

        Test.startTest();
        List<OpportunityDealAnalyzerAction.Response> responses = 
            OpportunityDealAnalyzerAction.analyzeDeal(new List<OpportunityDealAnalyzerAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isTrue(responses[0].isSuccess, 'Execution should be successful using Fuzzy Name');
    }

    @IsTest
    static void testAnalyzeDealNotFound() {
        OpportunityDealAnalyzerAction.Request req = new OpportunityDealAnalyzerAction.Request();
        req.opportunityId = 'NonExistentOpportunityName123';

        Test.startTest();
        List<OpportunityDealAnalyzerAction.Response> responses = 
            OpportunityDealAnalyzerAction.analyzeDeal(new List<OpportunityDealAnalyzerAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isFalse(responses[0].isSuccess, 'Should fail gracefully when Opportunity is not found');
    }

    @IsTest
    static void testAnalyzeDealBlankInput() {
        OpportunityDealAnalyzerAction.Request req = new OpportunityDealAnalyzerAction.Request();
        req.opportunityId = '';

        Test.startTest();
        List<OpportunityDealAnalyzerAction.Response> responses = 
            OpportunityDealAnalyzerAction.analyzeDeal(new List<OpportunityDealAnalyzerAction.Request>{ req });
        Test.stopTest();

        Assert.areEqual(1, responses.size(), 'Should return one response');
        Assert.isFalse(responses[0].isSuccess, 'Should fail gracefully when input is blank');
    }
}