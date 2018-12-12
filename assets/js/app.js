// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in 'brunch-config.js'.
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from 'config.paths.watched'.
import "@babel/polyfill";
import 'phoenix_html';
import WebFont from 'webfontloader';
import bowser from 'bowser';

const browser = bowser.getParser(window.navigator.userAgent);
if (browser.getBrowserName() === "Internet Explorer") {
  WebFont.load({
	  custom: {
		  families: ['FontAwesome'],
		  urls: ['https://use.fontawesome.com/releases/v5.0.4/css/all.css']
	  }
  });
}


// Import local files
//
// Local files can be imported directly using relative
// paths './socket' or full ones 'web/static/js/socket'.

import React from 'react';
import { render } from 'react-dom';
import { createStore, applyMiddleware, compose } from 'redux';
import { Provider, connect } from 'react-redux';
import thunk from 'redux-thunk';
import rootReducer from './reducers/index';
import { receiveAuctionFormData, impersonateUser } from './actions';
import AuctionFormContainer from './containers/auction-form-container';
import AuctionsContainer from './containers/auctions-container';
import AuctionContainer from './containers/auction-container';
import MessagesContainer from './containers/messages-container';


function getDataForComponent(componentName) {
  let data = document.getElementById(componentName).dataset;
  let auction = JSON.parse(data.auction);
  let suppliers = JSON.parse(data.suppliers);
  let fuels = JSON.parse(data.fuels);
  let ports = JSON.parse(data.ports);
  let vessels = JSON.parse(data.vessels);
  let credit_margin_amount = data.credit_margin_amount;
  return <AuctionFormContainer auction={auction} suppliers={suppliers} fuels={fuels} ports={ports} vessels={vessels} credit_margin_amount={credit_margin_amount} />;
}

let currentUserCompanyId = null;
if (window.companyId && window.companyId != "") {
  currentUserCompanyId = window.companyId;
}

if (document.getElementById('auctions-app')) {
  const store =
    window.__REDUX_DEVTOOLS_EXTENSION__
      ? createStore(
        rootReducer,
        compose(
            applyMiddleware(thunk),
            window.__REDUX_DEVTOOLS_EXTENSION__()
        ))
      : createStore(
          rootReducer,
          compose(
            applyMiddleware(thunk)
        ));

  const setContainer = () => {
    switch (window.container) {
      case "index": { return (
        <div>
          <AuctionsContainer currentUserCompanyId={currentUserCompanyId} />
          <MessagesContainer currentUserCompanyId={currentUserCompanyId} />
        </div>
      )}
      case "show": { return (
        <div>
          <AuctionContainer currentUserCompanyId={currentUserCompanyId} />
          <MessagesContainer currentUserCompanyId={currentUserCompanyId} />
        </div>
      )}
      case "edit": { return getDataForComponent("AuctionFormContainer")}
      case "new": { return getDataForComponent("AuctionFormContainer")}
      default: {return(<div></div>)}
    }
  };

  render((
      <Provider store={store}>
        {setContainer()}
      </Provider>
  ), document.getElementById('auctions-app'));
}
