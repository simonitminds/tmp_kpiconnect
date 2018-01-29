import React from 'react';
import { Link } from 'react-router';

const AppRoute = (props)=> {
  return (
    <div>
      <header className="header">
        <nav role="navigation" className="navbar is-primary is-fixed-top">
          <div className="navbar-brand">
            <Link to="/auctions" className="navbar-item">
              <img className="utility-head__logo js-msLogo" src="../images/ocm_transparentlogo_reverse.png"/>
            </Link>
          </div>

          <div className="navbar-menu">
            <div className="navbar-end">
            </div>
          </div>
        </nav>
      </header>
      <div id="wrapper">
        {props.children}
      </div>
    </div>
  )
}

export default AppRoute;
