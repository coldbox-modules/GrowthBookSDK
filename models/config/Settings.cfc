component {

    function configure() {
        return {
            apiHost : 'https://cdn.growthbook.io',
            clientKey : '',
            enabled : true,
            allowUrlOverrides : false,
            encryptionKey : '',
            isQaMode : false,
            FeatureRefreshStrategy : 'SERVER_SENT_EVENTS', // SERVER_SENT_EVENTS / STALE_WHILE_REVALIDATE
            dataSource : {
                // Possible options: default, fileData
                type : 'default',
                fileDataPath : ""
            },
            userAttributesProvider : ()=>{},
            // Called every time feature is used regardles of the source of the value.  If a trackingCallBack is also configured, feature evaluations which
            // involved an experiement will fire BOTH callbacks.
            featureUsageCallback : '', // ( featureResult )=>{}
            // Called ONLY if an experiment was run.  Will not be called if a feature is evaluated with direct value or if an 
            // experiment is at play but not affecting 100% of the samples and didn't affect this decision.
            trackingCallback: '' // ( experiment, experimentResult )=>{}
        };
    }

}