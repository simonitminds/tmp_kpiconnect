import _ from 'lodash';
import React from 'react';
import { formatUTCDateTime } from '../../../../utilities';
import moment from 'moment';
import LogLink from './log-link';
import SidebarDetails from './sidebar-details';
import InvitedSuppliers from '../../common/invited-suppliers';
import InvitedObservers from '../../common/show/observers/invited-observers'

const BuyerSidebar = (props) => {
  const {
    auctionPayload,
    approveBargeForm,
    rejectBargeForm,
    inviteObserver,
    uninviteObserver
  } = props;

  const { auction, status } = auctionPayload;
  const fuel = _.get(auction, 'fuel');
  const isAdmin = window.isAdmin;
  const isImpersonating = window.isImpersonating;
  const isObserver = window.isObserver;
  const isEditable = status != 'open' && status != 'decision';

  return (
    <React.Fragment>
      { !isObserver &&
        <div className="box">
          <h3 className="box__header box__header--bordered has-margin-bottom-md">Auction Reports</h3>
          { (isAdmin || (status != 'pending')) &&
            <LogLink auction={auction} />
          }
        </div>
      }
      { isAdmin && !isImpersonating && status != 'closed' && status != 'canceled' && status != 'expired' &&
        <InvitedObservers
          auctionPayload={auctionPayload}
          inviteObserver={inviteObserver}
          uninviteObserver={uninviteObserver}
        />
      }
      <InvitedSuppliers
        auctionPayload={auctionPayload}
        approveBargeForm={approveBargeForm}
        rejectBargeForm={rejectBargeForm}
      />
      <SidebarDetails auctionPayload={auctionPayload} isEditable={isEditable} />
    </React.Fragment>
  );
};

export default BuyerSidebar;
