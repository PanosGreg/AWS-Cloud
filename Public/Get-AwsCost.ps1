function Get-AwsCost ([string]$Since) {
<#
.SYNOPSIS
    It shows you the current AWS bill since last month [default]
.DESCRIPTION
    It shows you the current AWS bill isnce last month.
    if you get no result, it means you are not in the AWS service long enough,
    try reducing the start date.
.PARAMETER Since
    The format for this parameter is day/month/year,
    for ex. 22/10/19 for 22nd of October 2019

.EXAMPLE
    Get-AwsCost
.EXAMPLE
    Get-AwsCost -Since 1/10/19
#>

    $interval = [Amazon.CostExplorer.Model.DateInterval]::new()
    
    if (-not $PSBoundParameters.ContainsKey('Since')) {
        $interval.Start = [datetime]::Now.AddMonths(-1).ToString('yyyy-MM-dd') # ex. '2019-10-01'
    }
    else {$interval.Start = Get-Date $Since -Format 'yyyy-MM-dd'}

    $interval.End   = [datetime]::Now.ToString('yyyy-MM-dd')                   # ex. '2019-10-21'
    $params = @{
        Granularity = 'MONTHLY'
        TimePeriod  = $interval
        Metric      = 'BLENDED_COST'
    }
    (Get-CECostAndUsage @params).ResultsByTime.Total['BlendedCost']

    <# [the following are case sensitive]

    Options for Metric:
        BLENDED_COST
        UNBLENDED_COST
        AMORTIZED_COST
        NET_AMORTIZED_COST
        NET_UNBLENDED_COST
        USAGE_QUANTITY
        NORMALIZED_USAGE_AMOUNT

    Options for Granularity:
        MONTHLY
        DAILY
        HOURLY

    Note: the BlendedCost property is case sensitive in resultsbytime.total['BlendedCost']
    #>
}