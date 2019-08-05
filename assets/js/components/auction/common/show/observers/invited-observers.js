import React, { useState } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';

const InvitedObservers = ({ auctionPayload, inviteObserver, uninviteObserver }) => {
  const observers = _.get(auctionPayload, 'observers');
  const availableObservers = _.get(auctionPayload, 'available_observers')
  console.log(auctionPayload)
  console.log(availableObservers)
  const [invitedObservers, invite] = useState(
    _.reduce(availableObservers, (acc, observer) => {
      acc.set(observer.id, false)
    }, {})
  )
  const auctionId = _.get(auctionPayload, 'auction.id');

  const isInvited = (observerId) => {
    return invitedObservers[observerId];
  }

  return (
    <div className='box'>
      <h3 className='box__header'>Invited Observers</h3>
      <div className='invite-selector__container qa-auction-observers'>
        { _.map(availableObservers, (observer) => {
            const fullname = `${observer.user.first_name} ${observer.user.last_name}`
            return (
              <div className='invite-selector' key={observer.id}>
                <label className='invite-selector__checkbox' htmlFor={`invite-${observer.id}`}>
                  <input
                    type='checkbox'
                    className={`qa-auction-observer-${observer.id}`}
                    id={`invite-${observer.id}`}
                    value={observer.id}
                    checked={isInvited(observer.id)}
                    onChange={(ev) => {
                      if (ev.target.checked) {
                        uninviteObserver(auctionId, observer.user_id);
                        invite(invitedObservers.set(observer.id, false));
                      } else {
                        inviteObserver(auctionId, observer.user_id);
                        invite(invitedObservers.set(observer.id, true));
                      }
                    }} />
                    <span className="invite-selector__facade">
                      <FontAwesomeIcon icon={isInvited(observer.id) ? "check" : "plus"} className="default-only" />
                      <FontAwesomeIcon icon="minus" className="hover-only" />
                    </span>
                    <span className="invite-selector__label">{fullname}</span>
                </label>
              </div>
            );
          })
        }
      </div>
    </div>
  );
}

export default InvitedObservers;
