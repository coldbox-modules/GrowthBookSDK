/**
*********************************************************************************
* Copyright Since 2021 GrowthBook SDK by Brad Wood and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* This is the main GrowthBook Client
*/
component accessors=true singleton {

	property name="wirebox" inject="wirebox";

	property name="settings";
	property name="coldbox";
	property name="isColdBoxLinked";
	property name="log";

    variables.growthBookClass = createObject( 'java', 'growthbook.sdk.java.GrowthBook' );
    variables.GBContextClass = createObject( 'java', 'growthbook.sdk.java.GBContext' );
    variables.GBFeaturesRepositoryClass = createObject( 'java', 'growthbook.sdk.java.GBFeaturesRepository' );
    variables.FeatureRefreshStrategyClass = createObject( 'java', 'growthbook.sdk.java.FeatureRefreshStrategy' );
    variables.ObjectClass = createObject( 'java', 'java.lang.Object' );

	/**
	 * Constructor
	 */
	function init( struct settings={} ){
		setSettings( arguments.settings );
        setColdBox( '' );
        setWirebox( '' );
		// If we have settings passed to the init, this is likely not
		// in WireBox context so just configure now
		if( arguments.settings.count() ) {
			configure();
		}

		return this;
	}

	/**
	 * onDIComplete
	 */
	function onDIComplete() {
		// If we have WireBox, see if we can get ColdBox
		if( !isNull( wirebox ) ) {
			// backwards compat with older versions of ColdBox
			if( wirebox.isColdBoxLinked() ) {
			    setColdBox( wirebox.getColdBox() );
			    setSettings( wirebox.getInstance( dsl='box:moduleSettings:GrowthBookSDK' ) );
			}
		}

		configure();
	}


    /**
    * Configure this client!
    */
	function configure() {

        if( !isSimpleValue( getWirebox() ) ) {
            setLog( getWirebox().getLogBox().getLogger( this ) );
        } else {
            // Logbox shim for complete legacy mode
            setLog( {
                info : function(message){_log(message,'info');},
                warn : function(message){_log(message,'warn');},
                error : function(message){_log(message,'error');},
                debug : function(message){_log(message,'debug');}
            } );
        }

        if( !isColdBoxLinked() ) {

            // Manully append default settings
            settings.append(
                getDefaultSettings(),
                false
            );
        }

        log.info( 'GrowthBook SDK starting with the following config: #serializeJSON( settings.map( (k,v)=>isCustomFunction(v)?'<closure>' : v ) )#' );

		if ( !len( settings.clientKey ) && ( settings.datasource.type ?: '' ) == 'default' ) {
   			log.warn( "GrowthBook requires an SDK Key, disabling..." );
			settings.enabled=false;
		}

        
        if( settings.datasource.type != 'fileData' ) {
            var repoBuilder = GBFeaturesRepositoryClass.builder()
                .apiHost( settings.apiHost )
                .clientKey( settings.clientKey )
                .refreshStrategy( FeatureRefreshStrategyClass.valueOf( uCase( trim( settings.FeatureRefreshStrategy ) ) ) );
    
            if( len( settings.encryptionKey ) ) {
                repoBuilder.encryptionKey( settings.encryptionKey );
            }
    
            variables.featureRepo = repoBuilder.build();
    
            featureRepo.initialize();
        }

	}

    /**
    * Is this client linked to ColdBox?
    *
    * @returns true if Coldbox is linked
    */
    function isColdBoxLinked() {
        return !isSimpleValue( getColdBox() );
    }

    /**
    * Get the default settings for the client.  This is only used when outside
    * of ColdBox and will read the "settings" struct from the ModuleConfig.cfc to
    * mimic how ColdBox loads default module settings
    *
    *
    * @returns A struct of default settings, or an empty struct if an error occurs reading the default settings.
    */
    function getDefaultSettings() {
        // All default settings externalized into this CFC for non-ColdBox reuse
        return new config.Settings().configure();
    }

    /**
    * A logbox shim when used outside of WireBox
    */
    private function _log( required message, type='debug' ) {
		writeDump( var="[#uCase( type )#] #message#", output='console' );
    }

    function getGrowthBook() {
        var featuresJSON = "{}";
        if( settings.datasource.type == 'fileData' ) {
            if( !len( settings.datasource.fileDataPath ) ) {
                throw( message='FileDataPath is required when using the fileData datasource.' );
            }
            featuresJSON = fileRead( expandPath( settings.datasource.fileDataPath ) );
        } else {
            featuresJSON = featureRepo.getFeaturesJson();
        }
        var userAttributes = "{}";
        userAttributes = serializeJSON( { 'id' : getTickCount() } )
        //Systemoutput( userAttributes, true );
        var contextBuilder = GBContextClass.builder()
            .enabled( settings.enabled )
            .allowUrlOverrides( settings.allowUrlOverrides )
            .isQaMode( settings.isQaMode )
            // allow override in context provider
            .url( cgi.HTTP_URL )
            // get from context provider
            .attributesJson( userAttributes )
            .featuresJson( featuresJSON );

            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( featureRepo.getFeaturesJson(), true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
            Systemoutput( "", true );
        if( len( settings.encryptionKey ) ) {
            contextBuilder.encryptionKey( settings.encryptionKey );
        }
        
        var context  = contextBuilder.build();
        return growthBookClass.init( context );
    }

    /* *****************************************************************************
    * SDK Methods
    ******************************************************************************** */


    /**
    * Check if a feature is on
    *
    * @featureKey Name of the feature key you'd like to check
    *
    * @returns A boolean true if the feature is on, false if it is off
    */
    boolean function isOn( required string featureKey ) {
        return getGrowthBook().isOn( arguments.featureKey );
    }
    

    /**
    * Check if a feature is off
    *
    * @featureKey Name of the feature key you'd like to check
    *
    * @returns A boolean true if the feature is off, false if it is on
    */
    boolean function isOff( required string featureKey ) {
        return getGrowthBook().isOff( arguments.featureKey );
    }
    
    /**
    * Check if a feature is enabled for this environment
    *
    * @featureKey Name of the feature key you'd like to check
    *
    * @returns A boolean true if the feature is enabled, false if it is not
    */
    boolean function isFeatureEnabled( required string featureKey ) {
        return getGrowthBook().isFeatureEnabled( arguments.featureKey );
    }
    
    /**
    * Get the value of a feature
    *
    * @featureKey Name of the feature key you'd like to get the value of
    * @defaultValue Default value to return if the feature is not found
    *
    * @returns A boolean true if the feature is on, false if it is off
    */
    any function getFeatureValue( required string featureKey, any defaultValue="" ) {
        var result = getGrowthBook().getFeatureValue( arguments.featureKey, defaultValue, ObjectClass.getClass() );
        if( !isSimpleValue( result ) && result.getClass().getName() contains 'gson' ) {
            return deserializeJSON( result.toJSON() );
        }
        return result;
    }
    
    /**
    * Evaluate a feature
    *
    * @featureKey Name of the feature key you'd like to get the value of
    *
    * @returns 
    */
    any function evalFeature( required string featureKey ) {
        var result = getGrowthBook().evalFeature( arguments.featureKey, ObjectClass.getClass() );
        return deserializeJSON( result.toJSON() );
    }
      

    /**
    * Shuts down the GB Client.  This MUST be called in order to release internal resources
    */
    function shutdown() {
        log.info( 'GrowthBook SDK shutting down.' );
    }

}
