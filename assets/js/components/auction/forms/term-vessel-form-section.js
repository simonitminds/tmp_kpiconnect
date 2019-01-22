import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import _ from 'lodash';

export default class TermVesselFormSection extends React.Component {
  constructor(props) {
    super(props);

    const vessels = this.props.vessels;
    const selectedVessels = _.chain(vessels).map('vessel_id').uniq().filter().value();
    this.state = {
      selectedVessels: selectedVessels
    };
  }

  addVessel(ev) {
    const selectedElement = ev.target;
    const vessel_id = selectedElement.value;
    this.setState((previousState) => ({
      selectedVessels: _.uniq([...previousState.selectedVessels, vessel_id])
    }));
    selectedElement.value = "";
  }

  removeVessel(vessel_id) {
    this.setState((previousState) => ({
      selectedVessels: _.reject(previousState.selectedVessels, (v) => v == vessel_id)
    }));
  }

  render() {
    const { auction, vessels, portId, ports } = this.props;
    const availableVessels = _.reject(vessels, (v) => {
      return _.some(this.state.selectedVessels, (sv) => v.id == sv);
    });

    const renderVessel = (vessel_id) => {
      const vessel = _.find(vessels, (v) => v.id == vessel_id);

      return (
        <div className={`is-flex is-flex-wrapped qa-auction-vessel-${vessel.id}`} key={vessel.id}>
          <span className="selected-list__item-title">{vessel.name}, {vessel.imo}</span>
          <span className="selected-list__item-delete" onClick={(ev) => {
            this.removeVessel(vessel.id);
            ev.preventDefault();
          }}>
            <FontAwesomeIcon icon="times" />
          </span>
          <input type="hidden" name={`auction[vessels][${vessel.id}][selected]`} value={true} />
        </div>
      );
    };

    return (
      <section className="auction-info is-gray-1"> {/* Vessels info */}
        <div className="container">
          <div className="content">
            <fieldset>
              <legend className="subtitle is-4" >Vessels</legend>
              <div className="field is-horizontal">
                <div className="field-label">
                  <label htmlFor="auction_vessel_id" className="label">
                    Vessel Name
                  </label>
                </div>
                <div className="field-body field-body--select">
                  <div className="selected-list selected-list--vessels box qa-auction-selected-vessels">
                    {_.map(this.state.selectedVessels, renderVessel)}
                  </div>
                  <div className="control has-icons-left has-margin-right-none">
                    <div className="select is-fullwidth">
                      <select
                        className="qa-auction-select-vessel"
                        onChange={this.addVessel.bind(this)}
                        defaultValue=""
                      >
                        <option disabled value="" >
                          Add a Vessel
                        </option>
                        {_.map(availableVessels, vessel => (
                          <option key={vessel.id} value={vessel.id} id={vessel.id}>
                            {vessel.name}, {vessel.imo}
                          </option>
                        ))}
                    </select>
                    <div className="icon is-small is-left">
                      <FontAwesomeIcon icon="plus" />
                    </div>
                    </div>
                  </div>
                </div>
              </div>
            </fieldset>
          </div>
        </div>
      </section>
    );
  };
}
