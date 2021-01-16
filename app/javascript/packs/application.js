// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

Rails.start()
Turbolinks.start()
ActiveStorage.start()

import  "../stylesheets/application.scss";

import CableReady from 'cable_ready'

CableReady.DOMOperations['logicalSplit'] = detail => {
  const crId = document.querySelector('meta[name="cable_ready_id"]').content
  const custom = Object.entries(detail.customHtml).find(pair => pair[0].includes(crId))
  const html = custom ? custom[1] : detail.defaultHtml
  CableReady.DOMOperations[detail.operation]({
    element: detail.element,
    html: html,
    ...detail.additionalOptions
  })
}

import "controllers"
