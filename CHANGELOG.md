# 3.1.0
- use flatten section on search
- add options to always show search bar
- fix wrong section name on setting, favourite and search
- sort cell inside flatten section by name

# 3.0.0
- Add new Flatten home design.
- Expose TPTweakStore environment.
- Expose internal setting TPTweakEntry
- Fix sometimes accessorry cell type is rendered inaccurately.
- Improve Minimizable 
- remove `DevTools` subpsec as it is replace with exposed TPTWeakStore environment.
- Improve search logic with generated metadata

# 2.0.2
- Add `DevTools` subspec to give developer more control whether to enable TPTweak or not.

# 2.0.1
- fix the empty search page shows favourite empty state message.
- restore tweak view controller if minimizable exists
- add delay before adding minimize bar button item on the child's navigation bar
- expose restoreTweaks so custom implementation can mutate the state
- bubble from now will be added to window instead of the top viewcontroller's view

# 2.0.0
- Minimizable TPTweakViewController with `TPTweakViewController.presentMinimizableTweaks`
- Hold navigation controller to peep the background(only available on non minimizable mode)
- now every option will have completions
- add Settings menu for setting up TPTweakViewController
- add an empty state message on the favourite page
- fix the favorite page not reflecting the latest value after modifying one of the cells.

# 1.2.0
- Add Search functionality ([#11](https://github.com/tokopedia/ios-tptweak/pull/11))
- Fix wrong detailText on cell ([#11](https://github.com/tokopedia/ios-tptweak/pull/11))
- disable switch reloadRows animation ([#11](https://github.com/tokopedia/ios-tptweak/pull/11))
- Add Favourite functionality ([#13](https://github.com/tokopedia/ios-tptweak/pull/13))

# 1.1.0
- Passing closure for switch type ([#9](https://github.com/tokopedia/ios-tptweak/pull/9))

# 1.0.0
- initial release
