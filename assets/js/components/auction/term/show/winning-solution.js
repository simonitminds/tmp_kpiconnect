import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../../../utilities';
import SolutionDisplay from './solution-display';

const WinningSolution = ({auctionPayload, supplierId}) => {
  const solution = _.get(auctionPayload, 'solutions.winning_solution');

  return(
    <div className="auction-solution__container">
      <div className="box">
        <div className="box__subsection has-padding-bottom-none">
          <h3 className="box__header box__header--bordered">Winning Solution</h3>
          {
            solution ?
              <SolutionDisplay auctionPayload={auctionPayload} solution={solution} title={"Winning Solution"} supplierId={supplierId} isExpanded={true} best={true} highlightOwn={true} className="qa-auction-winning-solution" />
              : <div className="auction-table-placeholder">
                <i>A winning bid was not selected before the decision time expired</i>
              </div>
          }
        </div>
      </div>
    </div>
  );
};
export default WinningSolution;
