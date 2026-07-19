// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// appkit's own controllers are pinned under appkit/controllers/*, a separate
// importmap namespace from our local controllers/*, so eagerLoadControllersFrom
// above won't find them — register the ones we use explicitly.
import ThemeController from "appkit/controllers/theme_controller"
application.register("theme", ThemeController)

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)
