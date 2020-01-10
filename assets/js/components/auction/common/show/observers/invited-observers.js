import React, { useState } from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';

const InvitedObservers = ({ auctionPayload, inviteObserver, uninviteObserver }) => {
  const observers = _.get(auctionPayload, 'observers');
  const availableObservers = _.get(auctionPayload, 'available_observers')
  const [invitedObservers, invite] = useState(
    _.reduce(availableObservers, (acc, observer) => {
      const invited = _.find(observers, ['id', observer.id]) ? true : false;
      return _.set(acc, observer.id, invited)
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
            const fullname = `${observer.first_name} ${observer.last_name}`
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
                        inviteObserver(auctionId, observer.id, ev);
                        invite(_.set(invitedObservers, observer.id, true));
                      } else {
                        uninviteObserver(auctionId, observer.id, ev);
                        invite(_.set(invitedObservers, observer.id, false));
                      }
                    }} />
                    <span className="invite-selector__facade">
                      <FontAwesomeIcon icon={isInvited(observer.id) ? "check" : "plus"} className="default-only" />
                      <FontAwesomeIcon icon={isInvited(observer.id) ? "minus" : "plus"} className="hover-only" />
                    </span>
                    <span className="invite-selector__label">{fullname}, {observer.company.name}</span>
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
