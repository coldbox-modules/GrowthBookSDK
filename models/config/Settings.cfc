component {

    function configure() {
        return {
            apiHost : 'https://cdn.growthbook.io',
            clientKey : '',
            enabled : false,
            allowUrlOverrides : false,
            encryptionKey : '',
            isQaMode : false,
            FeatureRefreshStrategy : 'SERVER_SENT_EVENTS', // SERVER_SENT_EVENTS / STALE_WHILE_REVALIDATE
            dataSource : {
                // Possible options: default, fileData
                type : 'default',
                fileDataPath : ""
            },
            contextProvider : ()=>{},
            flagChangeListener : '',
            // flagChangeListener : ( featureKey )=>writeDump( var="Flag [#featureKey#] changed!", output='console' );
            flagValueChangeListeners : [
                /*
                {
                    featureKey : 'my-feature',
                    user : { key : 12345 },
                    udf : ( oldValue, newValue )=>writeDump( var="Flag [test] changed from [#oldValue#] to [#newValue#]!", output='console' )
                },
                {
                    featureKey : 'another-feature',
                    udf : ( oldValue, newValue )=>{}
                }
                */
            ]
        };
    }

}