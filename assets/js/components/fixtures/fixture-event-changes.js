import React, { Fragment } from 'react';
import _ from 'lodash';
import { formatUTCDateTime, formatPrice } from '../../utilities';

const FixtureEventChanges = ({ event, eventType, changes, comment }) => {
  if (changes.length > 0) {
    return (
      <Fragment>
        <br />
        { _.map(changes, ([key, value]) => {
            const fieldName = () => {
              switch (key) {
                case 'eta':
                case 'etd':
                  return _.upperCase(key);
                default:
                  return _.capitalize(key);
              }
            }

          const valueForKey = (key, value) => {
            switch (key) {
              case 'eta':
              case 'etd':
                return value ? formatUTCDateTime(value) : '—';
              case 'price':
                return value ? '$' + formatPrice(value) : '—';
              case 'quantity':
                return value ? value + ' M/T' : '—';
              default:
                return value ? value : '—';
            }
          }

           return (
             <Fragment key={key}>
               <span className='has-text-weight-bold has-padding-right-sm'>{fieldName()}:</span>
               <span className={`qa-fixture-event-${event.id}-${key}`}>{valueForKey(key, value)}</span>
               <br />
             </Fragment>
           )
          })
        }
        { comment &&
          <Fragment>
            <div><span className='has-text-weight-bold has-padding-right-xs'>Comment:</span></div>
            <div><span>{comment}</span></div>
          </Fragment>
        }
      </Fragment>
    )
  } else {
    return null;
  }
}

export default FixtureEventChanges;
