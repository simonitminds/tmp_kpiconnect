import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../utilities';
import SolutionComment from './solution-comment';
import SolutionDisplay from './solution-display';

const WinningSolution = ({auctionPayload}) => {
  const solution = _.get(auctionPayload, 'solutions.winning_solution');

  return(
    <div className="auction-solution__container">
      <div className="box">
        <div className="box__subsection has-padding-bottom-none">
          <h3 className="box__header box__header--bordered">Winning Solution</h3>
          {
            solution ?
              <SolutionDisplay auctionPayload={auctionPayload} solution={solution} title={"Winning Solution"} best={true} />
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
