import _ from 'lodash';
import React from 'react';
import MediaQuery from 'react-responsive';
import DateRangeInput from '../date-range-input';

const FixtureFilterForm = (props) => {
  const {
    clearFilter,
    filterPayloads,
    fixturePayloads,
    handleTimeRange,
    startTimeRange,
    endTimeRange
  } = props;

  const availableAuctions = _
    .chain(fixturePayloads)
    .filter((payload) => payload.fixtures.length > 0)
    .map((payload) => payload.auction);

  const availableItems = (type) => {
    return _
      .chain(availableAuctions)
      .flatMap((auction) => auction[type])
      .reject((item) => item == undefined)
      .uniqBy('id')
      .orderBy(['name'])
      .value();
  }

  const availableVessels = availableItems('vessels');
  const availableSuppliers = availableItems('suppliers')
  const availableBuyers = availableItems('buyer');
  const availablePorts = availableItems('port');

  return (
    <section className="is-gray-1 has-margin-top-md has-margin-bottom-md">
      <div className="container">
        <div className="content has-padding-top-lg has-padding-bottom-md">
          <h2 className="has-margin-bottom-md"><legend className="subtitle is-4">Filter Auctions</legend></h2>
          <div className="historical-auctions__form">
            <form onChange={filterPayloads.bind(this)} onSubmit={clearFilter.bind(this)}>
              <div className="field">
                <div className="control">
                  <label className="label">Vessel</label>
                  <div className="select">
                    <select
                      name="vessel"
                      className="qa-filter-vessel_id"
                    >
                      <option value="" >Select Vessel</option>
                      { _.map(availableVessels, vessel => (
                        <option className={`qa-filter-vessel_id-${vessel.id}`} key={vessel.id} value={vessel.id}>
                          {vessel.name}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              <div className="field">
                <div className="control">
                  <label className="label">Port</label>
                  <div className="select">
                    <select name="port" className="qa-filter-port_id">
                      <option value="">Select Port</option>
                      {_.map(availablePorts, port => (
                        <option key={port.id} value={port.id} className={`qa-filter-port_id-${port.id}`}>
                          {port.name}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              <div className="field">
                <div className="control">
                  <label className="label">Buyer</label>
                  <div className="select">
                    <select name="buyer" className="qa-filter-buyer_id">
                      <option value="">Select Buyer</option>
                      {_.map(availableBuyers, buyer => (
                        <option key={buyer.id} value={buyer.id} className={`qa-filter-buyer_id-${buyer.id}`}>
                          {buyer.name}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
              </div>

              { availableSuppliers.length > 0 &&
                <div className="field">
                  <div className="control">
                    <label className="label">Supplier</label>
                    <div className="select">
                      <select name="supplier" className="qa-filter-supplier_id" >
                        <option value="">Select Supplier</option>
                          {_.map(availableSuppliers, supplier => (
                            <option key={supplier.id} value={supplier.id} className={`qa-filter-supplier_id-${supplier.id}`}>
                              {supplier.name}
                            </option>
                          ))}
                      </select>
                    </div>
                  </div>
                </div>
              }

              <MediaQuery query="(max-width: 599px)">
                <div className="field">
                  <div className="control">
                    <label className="label">Time Period</label>
                    <DateRangeInput
                      orientation={"vertical"}
                      startDate={startTimeRange}
                      endDate={endTimeRange}
                      onChange={handleTimeRange.bind(this)}
                    />
                  </div>
                </div>
              </MediaQuery>
              <MediaQuery query="(min-width: 600px)">
                <div className="field">
                  <div className="control">
                    <label className="label">Time Period</label>
                    <DateRangeInput
                      startDate={startTimeRange}
                      endDate={endTimeRange}
                      onChange={handleTimeRange.bind(this)}
                    />
                  </div>
                </div>
              </MediaQuery>
              <div className="field">
                <div className="control">
                  <button className="button">Clear Filter</button>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </section>
  );
}

export default FixtureFilterForm;
