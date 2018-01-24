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
import 'react-phoenix';
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
import { getAllAuctions} from './actions';
import AuctionsContainer from './containers/auctions-container';
import AuctionForm from './components/auction/AuctionForm';

window.Components = {
  AuctionForm
};

if (document.getElementById('auctions-app')) {
  const store = createStore(
    rootReducer,
    compose(
      applyMiddleware(thunk),
      window.__REDUX_DEVTOOLS_EXTENSION__ && window.__REDUX_DEVTOOLS_EXTENSION__()
    )
  );

  render((
    <Provider store={store}>
      <AuctionsContainer />
    </Provider>
  ), document.getElementById('auctions-app'));
}
