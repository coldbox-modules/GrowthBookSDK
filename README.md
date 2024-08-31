# GrowthBook CFML SDK

A CFML SDK for GrowthBook feature flags

## Requirements

This runs on Lucee 5+ and Adobe CF 2023+.  It may work on other versions, but I haven't tested it.
The SDK is set up as a ColdBox module, however it will also work with WireBox standalone or just a legacy app.

## Installation

Use CommandBox to install it:
```bash
install growthbooksdk
```

If you're allergic to CLI's, you can snag the code from Github or Forgebox, but it will be up to you to acquire the jar files referenced in the `box.json` and place them in the `/modules/GrowthBookSDK/lib` folder.

You must manually add the jars to your `Application.cfc`'s `this.javaSettings`.  This can be done pretty quickly with a little snippet like so (adjust the paths as necessary):
```js
this.javaSettings = {
	loadPaths = directorylist( expandPath( '/modules/GrowthBookSDK/lib' ), true, 'array', '*jar' ),
	loadColdFusionClassPath = true,
	reloadOnChange = false
};
```

Sometimes, CF needs a restart for this setting to work.  I don't know why, I just know I've seen it happen ¯\_(ツ)_/¯

## Usage

If you're a cool kid and using ColdBox, you can just inject the client class (called `GB`)...

```js
property name="GB" inject="GB@GrowthBookSDK";
```
and start using it...
```js
if( GB.isOn( 'my-feature-flag' ) ) {
    // enable awesomeness
}
```
The module will automatically shutdown the client when ColdBox reinits via the unicorn magic of ColdBox interceptors.
Configure the client in a ColdBox setting by adding to your `moduleSettings` struct in `/config/Coldbox.cfc`.  (All config values listed below)

```js
moduleSettings = {
  'GrowthBookSDK' : {
      clientKey : 'my-key-here'
  }
};
```

If you're using this library outside of ColdBox, there's a couple things you'll need to do manually.

### Create the client CFC (WireBox standalone)

Map the CFC in Wirebox's binder.  Pass your configuration as a struct to the mapping DSL.  The key names and values are the same as what you'd put in the ColdBox config.  (All config values listed below)

```js
binder
    .mapPath( '/modules/GrowthBookSDK/models/GB.cfc' )
    .initArg(
        name='settings',
        value={
            clientKey : 'my-key-here'
        });
```

WireBox will create it as needed and automatically persist it as a singleton.  All you need to do is ask WireBox for it when you need it:

```js
wirebox.getInstance( 'GB' )
```

### Shutdown the client before re-creating it (WireBox standalone)

If you have code that re-creates your application like a framework reinit, you'll want to shutdown the old GB client CFC to release underlying resources before you recreate it again.

```js
wirebox.getInstance( 'GB' ).shutdown();
```

### Create the client CFC (Non-ColdBox/WireBox)

ONLY DO THIS ONCE AND STORE IT AS A SINGLETON.
Pass your configuration as a struct to the constructor.  The key names and values are the same as what you'd put in the ColdBox config.  (All config values listed below)

```js
application.GB = new growthBookSDK.models.GB( {
	clientKey:'my-key-here'
});
```

### Shutdown the client before re-creating it (Non-ColdBox/WireBox)

If you have code that re-creates your application like a framework reinit, you'll want to shutdown the old GB client CFC to release underlying resources before you recreate it again.

```js
application.GB.shutdown();
```

## Configuration

Here's a list of the currently-support config items.  These can go in your `/config/Coldbox.cfc` or can be passed as a struct to the `GB` constructor in non-ColdBox mode.


* `apiHost` : Only set this if using a self-hosted version of GrowthBook. Defaults to `https://cdn.growthbook.io`
* `clientKey` : Pass your client key for Growthbook, which is configured to a specific environment
* `enabled` : Whether to enable the SDK.  When false, default values are returned and no experiments run.  Defaults to true.
* `allowUrlOverrides` : Whether to allow URL overrides of rules
* `encryptionKey` : Set this if using encryption
* `isQaMode` : Whether to enable QA mode.
* `FeatureRefreshStrategy` : One of the following: `SERVER_SENT_EVENTS` (default) or `STALE_WHILE_REVALIDATE`
* `dataSource.type` : One of the following options: `default` (pulls data from the API), `fileData` (uses local JSON file for testing or offline operation)
* `dataSource.fileDataPath` : An absolute path to a JSON of features.  Only required if using `fileData` type.
* `userAttributesProvider` : A function that returns a struct of data describing the current user.  Function receives no arguments.
* `featureUsageCallback` : A function which will be called every time feature is used regardles of the source of the value.  If a trackingCallBack is also configured, feature evaluations which involved an experiement will fire BOTH callbacks.  Function receives a `featureKey` string and `featureResult` struct of data.
* `trackingCallback` : A function which will be called ONLY if an experiment was run.  Will not be called if a feature is evaluated with direct value or if an experiment is at play but not affecting 100% of the samples and didn't affect this decision.  Function receives a struct of `experiment` data and a struct of `experimentResult` data.

```js
{
    clientKey=getSystemSetting( 'clientKey', '' ),
    datasource:{
        type : 'default', // fileData
        fileDataPath : "/tests/data/test-flags.json"
    },
    FeatureRefreshStrategy : 'SERVER_SENT_EVENTS',
    userAttributesProvider : function() {
        return {
            "id" : createUUID(),
            "foo": "bar"
        };
    },
    featureUsageCallback : ( featureKey, featureResult )=>{
        SystemOutput( "Feature Usage: #featureKey# returned #serializeJSON( featureResult )#", true );
    },
    trackingCallback : ( experiment, experimentResult )=>{
        SystemOutput( "Experiment: #serializeJSON(experiment)#", true );
        SystemOutput( "Experiment Result: #serializeJSON( experimentResult )#", true );
    }
}
```


## Check if a feature is on or off

You can get a simple on/off check for boolean feature flags, or any feature flag which returns a boolean value. 

```js
if( GB.isOn(  'my-feature-flag' ) ) {
    // enable awesomeness
}
// or...

if( GB.isOff(  'my-feature-flag' ) ) {
    // disable awesomeness
}
```

Only the following values are considered to be "falsy":

* `null`
* `false`
* `""`
* `0`

Everything else is considered "truthy", including empty arrays and objects.


## Get feature flag value

You can also get the value of a feature flag with the `.getFeatureValue()` method.  The value can be a boolean, string, number, or even JSON, which will come back deserialized.  You can provide a default value.

```js
if( GB.getFeatureValue( 'my-boolean-feature', false ) ) {
    // enabled
}

var colWidth = GB.getFeatureValue( 'homepage-columns', 3 );

var welcomeText = GB.getFeatureValue( 'homepage-welcome-text', 'Get off my lawn!' );

var shoppingCartConfig = GB.getFeatureValue(
    'shopping-cart-config',
    {
        allowCoupons : true,
        experiemntalFeatures : false,
        autoCalcTaxes : true
    } );
```

## Debug feature flag calls

If you want to get the low-down on why a feature value was returned and if it was the result of an experiement such as a percentage rollout, you can use the `.evalFeature()` method.  The results that come back will be a struct with all the details you can dump out and look at.

```js
var results = GB.evalFeature( 'my-feature' );
writeDump( results )
```

## Check if flag is enabled for this environment

You can check if a flag is enabled.  Note, this is not the same as check if the flag evaluates to a truthy value, this checks if the actual feature flag itself is defined. 

```js
var isEnabled = GB.isFeatureEnabled( 'question-feature' )
```

## User Attributes Tracking

When evaluating a flag, this can be done in the context of user attributes, which will ensure the same user gets the same value on subsequent evaluations, and allows you to build rules for features to be based on details about the user.  You can can pass a struct of attributes directly to the following methods:


```js
GB.isOn(  featureKey='my-feature-flag', userAttributes={ id : 123 } )
GB.isOff(  featureKey='my-feature-flag', userAttributes={ id : 123 } )
GB.getFeatureValue(  featureKey='my-feature-flag', userAttributes={ id : 123 } )
GB.evalFeature(  featureKey='my-feature-flag', userAttributes={ id : 123 } )
```

However, the recommended approach is to use the `userAttributesProvider` setting for the library which allows you to set a single UDF that returns all the details for whatever context is currently logged in.  In this way, you can have that logic all in one place, pulling from the session scope, or wherever you track the current context.  The only built-in attribut is `id`, but you can include whatever else you want about the user.  Feel free to cache this information in the `session` scope so you aren't doign any sort of expensive DB lookups on every request.

If you provide no user attributes, we will default the `id` to the current client IP address.

## Listening for flag evaluations

You are required to track any data about what users are given what variations and the results of such.  You can register a global "feature usage" function to log every time a feaure is evaluated. 
```js
{
    clientKey='my-key',    
    featureUsageCallback : ( featureKey, featureResult )=>{
        SystemOutput( "Feature Usage: #featureKey# returned #serializeJSON( featureResult )#", true );
    }
}
```

The `featureKey` will contain the string name of the feature which was being evaluated.

The `featureResult` struct will look like this:
```js
{
	"on": true,
	"off": false,
	"value": true,
	"experiment": null,
	"experimentResult": null,
	"source": "force"
}
```

Of course, the values may differ for your use case, but the keys will be the same.  If an experiment was used, the `experiment` and `experiementResult` keys will be structs of data (see below).

You can also pass a closure to each of the flag evaluation methods in the SDK to provide an ad-hoc callback which is not global and only applies to that call.  This is ideal if you use a lot of flags, but only want to track details for a few of them.

```js
if( GB.isOn( featureKey='my-feature-flag', featureUsageCallback=( key, result )=>logFeatureUsage( key, result ) ) ) {
    // enable awesomeness
}
```

## Listening for experiment evaluations

If you ONLY care about feature usage which has a configured experiment, then you can register a global "tracking callback" function to log ONLY when experiements were evaluated.  Note if you have both a `featureUsageCallback` and a `trackingCallback` listener, they will both be called when an experiment was used, but ONLY the feature usage callback will fire if there was no experiment used, including when only a percentage of traffic uses the experiement and the current call fell outside out percentage of included users.

```js
{
    clientKey='my-key',    
    trackingCallback :  ( experiment, experimentResult )=>{
        SystemOutput( "Experiment: #serializeJSON(experiment)#, true );
        SystemOutput( "Experiment Result: #serializeJSON( experimentResult )#", true );
    }
}
```

The `experiment` will contain a struct describing the experiement which was used.
```js
{
	"key": "experiment-key",
	"variations": [
		false,
		true
	],
	"weights": [
		0.5,
		0.5
	],
	"coverage": 1,
	"hashAttribute": "id",
	"hashVersion": 2,
	"meta": [
		{
			"key": "0",
			"name": "Control"
		},
		{
			"key": "1",
			"name": "Variation 1"
		}
	],
	"seed": "5a5b9ad7-2664-4ec2-a650-78607a00e5a2",
	"name": "Human Readable Experiment Name",
	"phase": "1"
}
```

The `experimentResult` struct will look like this:
```js
{
	"value": false,
	"variationId": 0,
	"inExperiment": true,
	"hashAttribute": "id",
	"hashValue": "1AB89BD5-B8E3-4D6C-8FFC9BABF829C4FB",
	"featureId": "my-ab-boolean",
	"hashUsed": true,
	"key": "0",
	"name": "Control",
	"bucket": 0.3239,
	"stickyBucketUsed": false
}
```

You can also pass a closure to each of the flag evaluation methods in the SDK to provide an ad-hoc callback which is not global and only applies to that call.  This is ideal if you use a lot of flags, but only want to track details for a few of them.

```js
if( GB.isOn( featureKey='my-feature-flag', trackingCallback=( experiment, result )=>logExperimentResult( experiment, result ) ) ) {
    // enable awesomeness
}
