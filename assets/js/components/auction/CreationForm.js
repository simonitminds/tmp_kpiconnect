import React from 'react';

class CreationForm extends React.Component {
  constructor(props) {
    super(props);
    // this.state = {
    //   auction: props.auction,
    //   errors: props.errors,
    //   action: props.action
    // };
  }
  render() {
    return (
      <div>
        <div className="field">
          <label htmlFor="auction_vessel" className="label">
            Vessel
          </label>
          <div className="control">
            <input
              type="text"
              name="auction[vessel]"
              id="auction_vessel"
              className="input"
              defaultValue={this.props.auction.vessel}
              autoComplete="off"
            />
          </div>
        </div>
      </div>
    );
  }
}

export default CreationForm;

// <%= if @changeset.action do %>
//   <div className="alert alert-danger">
//     <p>Oops, something went wrong! Please check the errors below.</p>
//   </div>
// <% end %>
//
// onChange={e => this.props.updateProposal('company', e.target.value)}
// value={this.props.auction.vessel}
// className={this.props.proposal.errors.company ? 'error' : ''}
