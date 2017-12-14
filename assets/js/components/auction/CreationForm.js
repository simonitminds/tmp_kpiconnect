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
        <div className="form-group">
          <label htmlFor="auction_vessel">Vessel</label>
          <input
            type="text"
            name="auction[vessel]"
            id="auction_vessel"
            defaultValue={this.props.auction.vessel}
            autoComplete="off"
          />
        </div>

        <div className="form-group">
          <label htmlFor="auction_port">Port</label>
          <input
            type="text"
            name="auction[port]"
            id="auction_port"
            defaultValue={this.props.auction.port}
            autoComplete="off"
          />
        </div>

        <div className="form-group">
          <label htmlFor="auction_company">Company</label>
          <input
            type="text"
            name="auction[company]"
            id="auction_company"
            defaultValue={this.props.auction.company}
            autoComplete="off"
          />
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
