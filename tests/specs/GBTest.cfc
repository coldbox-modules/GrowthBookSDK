component extends="testbox.system.BaseSpec"{

	function beforeAll() {
		GB = new models.GB( {
			clientKey=getSystemSetting( 'clientKey', '' ),
			datasource:{
				type : 'default', // fileData
				fileDataPath : "/tests/data/test-flags.json"
			},
			userAttributesProvider : function() {
				return {
					"id" : createUUID(),
					"FOO": "bar"
				};
			},
			xfeatureUsageCallback : ( featureKey, featureResult )=>{
				SystemOutput( "*********************************************************
				Feature Usage: #serializeJSON( featureResult )#", true );
			},
			xtrackingCallback : ( experiment, experimentResult )=>{
				SystemOutput( "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				Experiment: #serializeJSON(experiment)#
				Experiment Result: #serializeJSON( experimentResult )#", true );
			}
		} );
	}

	function afterAll() {
		if( !isNull( GB ) ) {
			GB.shutdown();
		}
	}

	function run(){

		describe( "GB Client", function(){

			describe( "Flag Variation Evaluation", function() {

				it("can check if features is on", function(){
					expect( GB.isOn( 'my-enabled-feature' ) ).toBe( true );
					expect( GB.isOn( 'my-disabled-feature' ) ).toBe( false );
				});

				it("can check if features is off", function(){
					expect( GB.isOff( 'my-enabled-feature' ) ).toBe( false );
					expect( GB.isOff( 'my-disabled-feature' ) ).toBe( true );
				});

				it("can get default feature value", function(){
					expect( GB.getFeatureValue( 'my-non-existent-feature', 'default-value' ) ).toBe( "default-value" );	
				});

				it("can get boolean feature value", function(){
					expect( GB.getFeatureValue( 'my-enabled-feature' ) ).toBe( true );
					expect( GB.getFeatureValue( 'my-disabled-feature' ) ).toBe( false );
				});

				it("can get string feature value", function(){
					expect( GB.getFeatureValue( 'my-string-feature' ) ).toBe( "my-value" );	
				});

				it("can get number feature value", function(){
					expect( GB.getFeatureValue( 'my-number-feature' ) ).toBe( 42 );	
				});

				it("can get JSON feature value", function(){
					expect( GB.getFeatureValue( 'my-json-feature' ) ).toBe(  {
						"brad": "wood",
						"arr" : [1,2,3],
						"test" : true
					  } );	
				});
				
				it("can check if features is enabled", function(){
					expect( GB.isFeatureEnabled( 'my-enabled-feature' ) ).toBe( true );
					expect( GB.isFeatureEnabled( 'my-non-existent-feature' ) ).toBe( false );
				});

				it("can check rollout feature", function(){
					var iterations = 5000;
					var trueCount = 0;
					var falseCount = 0;
					for( var i = 0 ; i < iterations ; i++ ) {
						if( GB.isOn( 'my-rollout-feature' ) ) {
							trueCount++;
						} else {
							falseCount++;
						}
					}
					// percent should be around 50%
					expect( round( (trueCount/iterations)*100) ).toBeBetween( 40, 60 );
					expect( round( (falseCount/iterations)*100) ).toBeBetween( 40, 60 );

				});

				it("can eval a feature", function(){
					var result = GB.evalFeature( 'my-ab-boolean' );
					expect( result ).toBeStruct();
					expect( result ).tohaveKey( "value" );
					expect( result.value ).toBeBoolean();
					var value = result.value;
					expect( result ).tohaveKey( "on" );
					expect( result.on ).toBeBoolean();
					expect ( result.on ).toBe( value );
					expect( result ).tohaveKey( "off" );
					expect( result.off ).toBeBoolean();
					expect ( result.off ).toBe( !value );

					expect( result ).tohaveKey( "source" );
					expect( result.source ).toBeString();
					expect( result.source ).toBe( "experiment" );
					
					expect( result ).tohaveKey( "experimentResult" );
					expect( result.experimentResult ).toBeStruct();
					expect( result.experimentResult ).tohaveKey( "value" );
					expect( result.experimentResult.value ).toBe( value );
					
					expect( result ).tohaveKey( "experiment" );
					expect( result.experiment ).toBeStruct();
					expect( result.experiment ).tohaveKey( "key" );
					expect( result.experiment.key ).toBe( "test" );
					expect( result.experiment ).tohaveKey( "name" );
					expect( result.experiment.name ).toBe( "test" );
					expect( result.experiment ).tohaveKey( "variations" );
					expect( result.experiment.variations ).toBeArray();
					expect( result.experiment.variations ).toBe( [ false, true ] );

					expect( result.experiment ).tohaveKey( "weights" );
					expect( result.experiment.weights ).toBeArray();
					expect( result.experiment.weights ).toBe( [ .5, .5 ] );

					expect( result.experiment ).tohaveKey( "coverage" );
					expect( result.experiment.coverage ).toBe( 1 );

					expect( result.experiment ).tohaveKey( "meta" );
					expect( result.experiment.meta ).toBeArray();
					expect( result.experiment.meta ).toBe( [
						{
							key : 0,
							name : "Control"
						},
						{
							key : 1,
							name : "Variation 1"
						}
					] );


				});

				it("can check a/b feature", function(){
					var iterations = 5000;
					var defaultCount = 0;
					var bradCount = 0;
					var luisCount = 0;
					var mikeCount = 0;
					for( var i = 0 ; i < iterations ; i++ ) {
						switch( GB.getFeatureValue( 'my-ab-feature' ) ) {
							case "default":
								defaultCount++;
								break;
							case "brad":
								bradCount++;
								break;
							case "luis":
								luisCount++;
								break;
							case "mike":
								mikeCount++;
								break;
						}
					}

					// percent should be around 25%
					expect( round( (defaultCount/iterations)*100 ) ).toBeBetween( 23, 27 );
					expect( round( (bradCount/iterations)*100 ) ).toBeBetween( 23, 27 );
					expect( round( (luisCount/iterations)*100 ) ).toBeBetween( 23, 27 );
					expect( round( (mikeCount/iterations)*100 ) ).toBeBetween( 23, 27 );

				});
				

				it("can check register one-off feature usage callback", function(){
					request.callbackName = '';
					request.callbackValue = '';
					expect( GB.isOn( 'my-enabled-feature', {}, ( featureKey, featureResult )=>{
						request.callbackName = featureKey;
						request.callbackValue = featureResult.value;
					} ) ).toBe( true );

					expect( request.callbackName ).toBe( 'my-enabled-feature' );
					expect( request.callbackValue ).toBe( true );

				});
			});

		});

	}

	function getSystemSetting( required key, defaultValue ){
		var value = getJavaSystem().getProperty( arguments.key );
		if ( !isNull( local.value ) ) {
			return value;
		}

		value = getJavaSystem().getEnv( arguments.key );
		if ( !isNull( local.value ) ) {
			return value;
		}

		if ( !isNull( arguments.defaultValue ) ) {
			return arguments.defaultValue;
		}

		throw(
			type   : "SystemSettingNotFound",
			message: "Could not find a Java System property or Env setting with key [#arguments.key#]."
		);
	}

	function getJavaSystem(){
		if ( !structKeyExists( variables, "javaSystem" ) ) {
			variables.javaSystem = createObject( "java", "java.lang.System" );
		}
		return variables.javaSystem;
	}
}
