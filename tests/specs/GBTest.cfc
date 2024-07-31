component extends="testbox.system.BaseSpec"{

	function beforeAll() {
		GB = new models.GB( {
			clientKey=getSystemSetting( 'clientKey', '' ),
			datasource:{
				type : 'default',
				fileDataPath : "/tests/data/test-flags.json"
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
					dump( GB.evalFeature( 'my-ab-feature' ) )
				});

				xit("can check a/b feature", function(){
					var defaultCount = 0;
					var bradCount = 0;
					var luisCount = 0;
					var mikeCount = 0;
					for( var i = 0 ; i < 100 ; i++ ) {
						switch( GB.evalFeature( 'my-ab-feature' ) ) {
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
dump( defaultCount );
dump( bradCount );
dump( luisCount );
dump( mikeCount );
					// percent should be around 25%
					expect( round( (defaultCount/100)*100 ) ).ToBe( 25 );

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
