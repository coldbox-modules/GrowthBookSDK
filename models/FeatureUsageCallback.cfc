/**
 * Functional interface that maps to java.util.function.Consumer
 * See https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/util/function/Consumer.html
 */
component extends="cbproxies.models.BaseProxy" {

	/**
	 * Constructor
	 *
	 * @callback a function to be called for our callback
	 */
	function init( required callback ){
		super.init( arguments.callback );
		return this;
	}

	/**
	 * See https://growthbook.github.io/growthbook-sdk-java/growthbook/sdk/java/FeatureUsageCallback.html#onFeatureUsage(java.lang.String,growthbook.sdk.java.FeatureResult)
	 */
	function onFeatureUsage( required String featureKey, required featureResult ){
		loadContext();
		try {
			lock name="#getConcurrentEngineLockName()#" type="exclusive" timeout="60" {
				variables.target( featureKey, deserializeJSON( featureResult.toJSON() ) );
			}
		} catch ( any e ) {
			// Log it, so it doesn't go to ether
			err( "Error running FeatureUsage Callback: #e.message & e.detail#" );
			err( "Stacktrace for FeatureUsage Callback: #e.stackTrace#" );
			sendExceptionToLogBoxIfAvailable( e );
			sendExceptionToOnExceptionIfAvailable( e );
			rethrow;
		} finally {
			unLoadContext();
		}
	}

}
