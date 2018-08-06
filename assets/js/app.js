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
import 'phoenix_html';
// Import local files
//
// Local files can be imported directly using relative
// paths './socket' or full ones 'web/static/js/socket'.

import React from 'react';
import { render } from 'react-dom';
import { createStore, applyMiddleware, compose } from 'redux';
import { Provider } from 'react-redux';
import thunk from 'redux-thunk';
import rootReducer from './reducers/index';
import { getAllAuctionPayloads, receiveAuctionFormData } from './actions';
import AuctionFormContainer from './containers/auction-form-container';
import AuctionsContainer from './containers/auctions-container';
import AuctionContainer from './containers/auction-container';
import AdminBar from './components/admin-bar';


function getDataForComponent(componentName) {
  let data = document.getElementById(componentName).dataset;
  let auction = JSON.parse(data.auction);
  let suppliers = JSON.parse(data.suppliers);
  let fuels = JSON.parse(data.fuels);
  let ports = JSON.parse(data.ports);
  let vessels = JSON.parse(data.vessels);
  return <AuctionFormContainer auction={auction} suppliers={suppliers} fuels={fuels} ports={ports} vessels={vessels} />;
}

let currentUserCompanyId = null;
if(window.companyId && window.companyId != ""){
  currentUserCompanyId = window.companyId;
}

if (document.getElementById('auctions-app')) {
  const store = createStore(
    rootReducer,
    compose(
      applyMiddleware(thunk)//,
      //window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__()
    )
  );

  const setContainer = () => {
    switch (window.container) {
      case "index": { return <AuctionsContainer currentUserCompanyId={currentUserCompanyId} /> }
      case "show": { return <AuctionContainer currentUserCompanyId={currentUserCompanyId} /> }
      case "edit": { return getDataForComponent("AuctionFormContainer")}
      case "new": { return getDataForComponent("AuctionFormContainer")}
      default: {return(<div></div>)}
    }
  };

  render((
      <AdminBar isAdmin={window.isAdmin} impersonableUsers={window.impersonableUsers}>
      <Provider store={store}>
          {setContainer()}
      </Provider>
    </AdminBar>
  ), document.getElementById('auctions-app'));
}
