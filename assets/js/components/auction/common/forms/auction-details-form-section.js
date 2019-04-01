import React from 'react';
import moment from 'moment';
import CheckBoxField from '../../../check-box-field';
import DateInput from '../../../date-input';
import InputField from '../../../input-field';
import InputErrors from '../../../input-errors';
import TimeInput from '../../../time-input';

const AuctionDetailsFormSection = (props) => {
  const {
    auction,
    errors,
    credit_margin_amount,
    isTermAuction,
    updateInformation,
    updateInformationFromCheckbox,
    updateDate
  } = props;
  return (
    <section className="auction-info is-gray-1"> {/* Auction details */}
      <div className="container">
        <div className="content">
          <fieldset>
            <legend className="subtitle is-4" >Auction Details</legend>

            <InputField
              model={'auction'}
              field={'po'}
              labelText={'po'}
              value={auction.po}
              errors={errors.po}
              isHorizontal={true}
              opts={{ labelClass: 'label is-uppercase' }}
              onChange={updateInformation.bind(this, 'auction.po')}
            />

            <div className="field is-horizontal">
              <div className="field-label">
                <label className="label">Auction Start</label>
              </div>
              <div className="field-body field-body--distribute-middle">
                <input type="hidden" name="auction[scheduled_start]" className="qa-auction-scheduled_start" value={auction.scheduled_start ? moment(auction.scheduled_start).utc() : ""} />
                <div className="control">
                  <DateInput value={auction.scheduled_start} model={'auction'} field={'scheduled_start'} labelText={'Auction Start'} onChange={updateDate.bind(this, 'scheduled_start_date')} />
                </div>
                <div className="control">
                  <TimeInput value={auction.scheduled_start} model={'auction'} field={'scheduled_start'} labelText={'Auction Start'} onChange={updateDate.bind(this, 'scheduled_start_time')} />
                </div>
                <div className="control has-text-gray-3 has-margin-right-sm">
                  (GMT)
                </div>
                <InputErrors errors={errors.scheduled_start} />
              </div>
            </div>

            <div className="field is-horizontal">
              <div className="field-label">
                <label htmlFor="auction_duration" className="label">
                  Duration
                </label>
              </div>
              <div className="field-body">
                <div className="control has-margin-right-sm">
                  <div className="select">
                    <select id="auction_duration" name="auction[duration]" defaultValue={auction.duration / 60000} className="qa-auction-duration" onChange={updateInformation.bind(this, 'auction.duration')}>
                      <option disabled value="">
                        Please select
                      </option>
                      <option value="10">10</option>
                      <option value="15">15</option>
                      <option value="20">20</option>
                    </select>
                  </div>
                  <span className="select__extra-label">minutes</span>
                </div>
                <InputErrors errors={errors.auction_duration} />
              </div>
            </div>

            <div className="field is-horizontal">
              <div className="field-label">
                <label htmlFor="auction_decision_duration" className="label">
                  Decision Duration
                </label>
              </div>
              <div className="field-body">
                <div className="control has-margin-right-sm">
                  <div className="select">
                    <select id="auction_decision_duration" name="auction[decision_duration]" defaultValue={auction.decision_duration / 60000} className="qa-auction-decision_duration" onChange={updateInformation.bind(this, 'auction.decision_duration')}>
                      <option disabled value="">
                        Please select
                      </option>
                      <option value="15">15</option>
                      <option value="10">10</option>
                    </select>
                  </div>
                  <span className="select__extra-label">minutes</span>
                </div>
                <InputErrors errors={errors.decision_duration} />
              </div>
            </div>

            <div className="field is-horizontal has-margin-bottom-md">
              <div className="field-label"></div>
              <div className="field-body">
                <CheckBoxField
                    model={'auction'}
                    field={'anonymous_bidding'}
                    labelText={'anonymous bidding'}
                    defaultChecked={auction.anonymous_bidding}
                    opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                    onChange={updateInformation.bind(this, 'auction.anonymous_bidding')}
                    className={'has-margin-right-sm'}
                />
                <InputErrors errors={errors.anonymous_bidding} />
              </div>
            </div>

            { (credit_margin_amount != 0) &&
                <div className="field is-horizontal">
                  <div className="field-label"></div>
                  <div className="field-body field-body--columned">
                    <CheckBoxField
                        model={'auction'}
                        field={'is_traded_bid_allowed'}
                        labelText={'accept traded bids'}
                        defaultChecked={auction.is_traded_bid_allowed}
                        opts={{labelClass: 'label is-capitalized is-inline-block has-margin-left-sm'}}
                        onChange={updateInformationFromCheckbox.bind(this, 'auction.is_traded_bid_allowed')}
                        className={'has-margin-right-sm'}
                    />
                    <InputErrors errors={errors.is_traded_bid_allowed} />
                    <div className="field-body__note" style={{display: auction.is_traded_bid_allowed === true ? `inline-block` : `none`}}>
                      <strong>Your Credit Margin Amount:</strong> $<span className="qa-auction-credit_margin_amount">{credit_margin_amount}</span>
                    </div>
                  </div>
                </div>
            }
          </fieldset>
        </div>
      </div>
    </section>
  );
};

export default AuctionDetailsFormSection;
