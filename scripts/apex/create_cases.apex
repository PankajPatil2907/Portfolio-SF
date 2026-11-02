List<Case> casesToInsert = new List<Case>{
    new Case(
        Subject = 'Solar Panel Inverter Failure - Error Code 402',
        Description = 'Customer reports inverter is blinking red and showing Error Code 402 since morning. No power output detected.',
        Status = 'New',
        Priority = 'High',
        Origin = 'Web'
    ),
    new Case(
        Subject = 'Billing Inquiry - Overcharged on Monthly Subscription',
        Description = 'Customer was charged twice for the September premium maintenance plan. Requesting refund of duplicate charge.',
        Status = 'New',
        Priority = 'Medium',
        Origin = 'Email'
    ),
    new Case(
        Subject = 'Mobile App Login & Password Reset Issue',
        Description = 'Unable to receive two-factor authentication SMS when attempting to log into the mobile app.',
        Status = 'Working',
        Priority = 'Medium',
        Origin = 'Phone'
    ),
    new Case(
        Subject = 'Urgent: Water Leak Detected Near Electrical Unit',
        Description = 'Safety emergency: Customer noticed moisture buildup and water dripping near the main circuit connection box.',
        Status = 'New',
        Priority = 'High',
        Origin = 'Phone'
    ),
    new Case(
        Subject = 'Product Warranty Extension Request',
        Description = 'Customer wants information on extending the standard 3-year warranty for model SF-2000 solar battery.',
        Status = 'New',
        Priority = 'Low',
        Origin = 'Web'
    )
};

insert casesToInsert;

List<Case> createdCases = [SELECT Id, CaseNumber, Subject, Priority, Status, Origin FROM Case WHERE Id IN :casesToInsert];
for (Case c : createdCases) {
    System.debug('CREATED_CASE: ' + c.CaseNumber + ' | ' + c.Id + ' | ' + c.Priority + ' | ' + c.Subject);
}
