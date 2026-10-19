package com.swmansion.rnscreens.core.containers.tabs.screen

fun interface TabsItemConfigurationObserver {
    /**
     * Reports that the parts of the tab's configuration described by [flags] changed.
     */
    fun onInvalidated(flags: TabsItemInvalidationFlags)
}
